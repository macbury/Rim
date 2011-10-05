module Rim
  class Stream
    Server = 0x0
    Client = 0x1
    
    Namespace = 'http://etherx.jabber.org/streams'
    
    attr_accessor :connection, :type, :stream_id, :host, :node
    
    state_machine :initial => :idle do
      state :idle do
        
        def response
          if self.node[:name] == "stream:stream"
            self.type = (self.node[:attributes]["xmlns"] == "jabber:client") ? Rim::Stream::Client : Rim::Stream::Server

            if server?
              Rim.logger.info "Server has connected..."
              close
            elsif client?
              Rim.logger.info "Client have connected..."
              run_client_auth
            else
              close
            end
          end
        end
        
      end
      
      after_transition :idle => :client_auth, :do => :send_head
      event :run_client_auth do
        transition :idle => :client_auth
      end
      
      state :client_auth do
        
        def response
          if self.node[:name] == "auth" && @auth.support?(self.node[:attributes]["mechanism"])
            @auth.use(self.node[:attributes]["mechanism"])
            Rim.logger.info "Sending chellange for client using #{@auth.mechanism} mechanism"
            wait_for_auth_response
            write(@auth.prepare_chellange)
          else
            Rim.logger.info "Unknown mechanism"
            close
          end
        end
        
        def send_head(attr)
          Rim.logger.info "Sending header and features."
          
          self.stream_id = "rim_"+(Time.new.to_f*100000).to_i.to_s(32)
          connection_type_name = client? ? "jabber:client" : "jabber:server"
          stanza = %(<?xml version='1.0'?>) +
                   %(<stream:stream ) +
                   %(xmlns='#{connection_type_name}' ) +
                   %(xmlns:stream='http://etherx.jabber.org/streams' ) +
                   %(from='#{self.host}' ) +
                   %(id='#{self.stream_id}' ) +
                   %(version='1.0'>)
    
          write(stanza)
          
          @auth = Rim::Auth.new
          features = REXML::Element.new('stream:features')
          features << @auth.features
          
          write(features)
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
          if self.node[:name] == "response" #&& self.node[:attributes] == "urn:ietf:params:xml:ns:xmpp-sasl"
            Rim.logger.info "Sending success response"
            
            write(@auth.success)
            begin_stream_with_features
          else
            Rim.logger.info "No success response"
            close
          end
        end
      end
      
      event :begin_stream_with_features do
        transition :wait_for_auth_success => :stream_with_features
      end
      
      state :stream_with_features do
        def response
          if self.node[:name] == "stream:stream"
            Rim.logger.info "Sending stream with features."
            connection_type_name = client? ? "jabber:client" : "jabber:server"
            stanza = %(<?xml version='1.0'?>) +
                     %(<stream:stream ) +
                     %(xmlns='#{connection_type_name}' ) +
                     %(xmlns:stream='http://etherx.jabber.org/streams' ) +
                     %(from='#{self.host}' ) +
                     %(id='#{self.stream_id}' ) +
                     %(version='1.0'>)
      
            write(stanza)
            
            features = REXML::Element.new('stream:features')
            write features
          else
            Rim.logger.info "Udefined tag #{self.node[:name]}"
            close
          end
            
        end
        
      end
    end
    
    def read(content)
      Rim.logger.debug content.blue
      
      @parser.source.buffer << content
      @parser.parse
      
      #if respond_to?(:recive, true)
      #  self.send(:recive, content)
      #end
    end
    
    def write(content)
      out = ""
      if content.kind_of?(REXML::Element)
        @formatter.write(content, out)
      else
        out = content
      end
      Rim.logger.debug out.green
      self.connection.send_data(out)
    end
    
    def error(defined_condition, application_error = nil)
      err = REXML::Element.new('stream:error')
      na  = REXML::Element.new(defined_condition)

      na.add_namespace('urn:ietf:params:xml:ns:xmpp-streams')
      err << na

      if application_error
        ae      = REXML::Element.new(application_error['name'])
        ae.text = application_error['text'] if application_error['text']

        ae.add_namespace('urn:xmpp:errors')
        err << ae
      end
      write(err)
      close
    end
    
    def initialize(host, connection)
      super()
      self.host = host
      self.connection = connection
      @formatter = REXML::Formatters::Default.new
      
      @parser  = REXML::Parsers::SAX2Parser.new('')
      self.node = {}
      
      @parser.listen(:start_element) do |uri, localname, qname, attributes|
        Rim.logger.debug ["Start tag:", qname, attributes].join(" ")
        self.node = { :name => qname, :attributes => attributes, :content => "" }
        response if qname == "stream:stream"
      end
      
      @parser.listen(:characters) do |text|
        self.node[:content] += text
      end
      
      @parser.listen(:end_element) do |uri, name, n|
        Rim.logger.debug ["End tag:", uri, name, n].join(" ")
        if name == "stream:stream"
          close
        else
          response
        end
      end
      
      Rim.logger.debug "XML dump legend:"
      Rim.logger.debug "Sending".green
      Rim.logger.debug "Reciving".blue
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
  end
end