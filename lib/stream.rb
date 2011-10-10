module Rim
  class Stream
    Server = 0x0
    Client = 0x1
    
    Namespace = 'http://etherx.jabber.org/streams'
    
    attr_accessor :connection, :type, :stream_id, :host, :node, :resource
    
    state_machine :initial => :idle do
      state :idle do
        
        def response
          if self.node.name == "stream"
            self.type = (self.node.attributes["xmlns"] == "jabber:client") ? Rim::Stream::Client : Rim::Stream::Server

            if server?
              Rim.logger.warn "Server has connected..."
              close
            elsif client?
              Rim.logger.info "Client have connected..."
              run_client_auth
              send_head
              
              @auth = Rim::Auth.new
              features = REXML::Element.new('stream:features')
              features << @auth.features
              write(features)
            else
              close
            end
          end
        end
        
      end
      
      event :run_client_auth do
        transition :idle => :client_auth
      end
      
      state :client_auth do
        def response
          if self.node.name == "auth" && @auth.support?(self.node.attributes["mechanism"])
            @auth.use(self.node.attributes["mechanism"])
            Rim.logger.info "Sending chellange for client using #{@auth.mechanism} mechanism"
            wait_for_auth_response
            write(@auth.prepare_chellange)
          else
            Rim.logger.warn "Unknown mechanism Implement!"
            close
          end
        end
      end
      
      event :wait_for_auth_response do
        transition :client_auth => :wait_for_auth_response
      end
      
      state :wait_for_auth_response do
        
        def response
          @auth.parse_response(self)
          wait_for_auth_success
        end
        
      end
      
      event :wait_for_auth_success do
        transition :wait_for_auth_response => :wait_for_auth_success
      end
      
      state :wait_for_auth_success do
        def response
          if self.node.name == "response" #&& self.node.attributes == "urn:ietf:params:xml:ns:xmpp-sasl"
            Rim.logger.info "Sending success response"
            
            write(@auth.success)
            begin_stream_with_features
          else
            Rim.logger.warn "No success response"
            raise FailureException.not_authorized(@auth.namespace)
          end
        end
      end
      
      event :begin_stream_with_features do
        transition :wait_for_auth_success => :stream_with_features
      end
      
      state :stream_with_features do
        def response
          if self.node.is?(:stream)
            send_head
            
            features = REXML::Element.new('stream:features')
            
            recbind = REXML::Element.new('bind')
            recbind.add_namespace('urn:ietf:params:xml:ns:xmpp-bind')
            recbind.add_element(REXML::Element.new('required')) if client?
            
            sess = REXML::Element.new('session')
            sess.add_namespace('urn:ietf:params:xml:ns:xmpp-session')
            sess.add_element(REXML::Element.new('optional'))
            
            features << sess
            features << recbind
            
            write features
          elsif self.node.is?(:iq)
            if self.node.bind?
              self.resource = Rim::Resource.parse(self.node)
              Rim.logger.info "User resource is #{self.resource.name}"
              write self.resource.success(@auth.jid)
            elsif self.node.session?
              Rim.logger.info "Session silently ignored"
              write self.node.make_result
            elsif self.node.query?
              
              if self.node.query.discoInfo?
                Rim.logger.info "Sending discovery info"
              elsif self.node.query.discoItems?
                Rim.logger.info "Sending discovery items"
              end
              
            end
          end
            
        end
        
      end
    end
    
    def send_head
      self.stream_id ||= Rim::Stream.uid
      
      Rim.logger.info "Sending stream header."
      connection_type_name = client? ? "jabber:client" : "jabber:server"
      stanza = %(<?xml version='1.0'?>) +
               %(<stream:stream ) +
               %(xmlns='#{connection_type_name}' ) +
               %(xmlns:stream='http://etherx.jabber.org/streams' ) +
               %(from='#{self.host}' ) +
               %(id='#{self.stream_id}' ) +
               %(version='1.0'>)
      write(stanza)
    end
    
    def read(content)
      @parser.source.buffer << content
      @parser.parse
    end
    
    def write(content)
      out = ""
      if content.kind_of?(REXML::Element)
        @formatter.write(content, out)
      else
        out = content
      end
      if Rim.env == :development
        Rim.logger.debug "<!-- OUT -->".green
        out.each_line do |line|
          
          Rim.logger.debug line.gsub("\n", "").green 
        end
      end
      self.connection.send_data(out)
    end
    
    def jid
      return if self.resource.name
      @auth.jid + "/" + self.resource.name
    end
    
    def initialize(host, connection)
      super()
      self.host = host
      self.connection = connection
      @formatter = Rim.env == :development ? REXML::Formatters::Transitive.new : REXML::Formatters::Default.new
      
      prepare_parser
      
      Rim.logger.debug "XML dump legend:"
      Rim.logger.debug "Sending".green
      Rim.logger.debug "Reciving".blue
    end
    
    def node
      @current
    end
    
    def _process_response
      begin
        if Rim.env == :development
          content = ""
          @formatter.write(self.node, content)
          Rim.logger.debug "<!-- IN -->".blue
          content.each_line do |line|
            Rim.logger.debug line.gsub("\n", "").blue 
          end
        end
        response
      rescue Rim::FailureException => exception
        self.write exception.xml
      rescue Rim::ErrorException => exception
        self.write exception.xml
        close
      rescue Exception => e
        Rim.logger.error e.to_s
        e.backtrace.each { |line| Rim.logger.debug line.red }
        write(Rim::ErrorException.new(self.node, 'internal-server-error', 'wait').xml)
      end
    end
    
    def prepare_parser
      @parser  = REXML::Parsers::SAX2Parser.new('')
      @current = nil

      @parser.listen(:start_element) do |uri, localname, qname, attributes|
        if qname == "iq"
          e = Rim::IQ.new
        elsif qname == "query"
          e = Rim::Query.new
        else
          e = Rim::Node.new(qname)
        end
        e.add_attributes(attributes)

        @current = @current.nil? ? e : @current.add_element(e)
        
        if @current.name == 'stream'
          _process_response
          @current = nil
        end
      end
  
      @parser.listen(:end_element) do |uri, localname, qname|
        if qname == 'stream:stream' and @current.nil?
          close
        else
          _process_response unless @current.parent
          @current = @current.parent
        end
      end
  
      @parser.listen(:characters) do |text|
        if @current
          rtx = REXML::Text.new(text.to_s, @current.whitespace, nil, true)
          @current.add(rtx)
        end
      end
  
      @parser.listen(:cdata) do |text|
        @current.add(REXML::CData.new(text)) if @current
      end
    end
    def client?
      self.type == Rim::Stream::Client
    end
    
    def server?
      self.type == Rim::Stream::Server
    end

    def close
      write("</stream:stream>")
      self.connection.close_connection(false)
    end
    
    def self.uid
      Rim.uid
    end
  end
end