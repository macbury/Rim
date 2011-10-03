module Rim
  class Stream
    Server = 0x0
    Client = 0x1
    
    Namespace = 'http://etherx.jabber.org/streams'
    
    attr_accessor :connection, :type, :stream_id, :host
    
    state_machine :initial => :idle do
      state :idle do
        
        def parse(tag,attributes)
          if tag == "stream:stream"
            self.type = (attributes["xmlns"] == "jabber:client") ? Rim::Stream::Client : Rim::Stream::Server

            unless attributes['xmlns:stream'] == Rim::Stream::Namespace
              error('invalid-namespace')
              Rim.logger.error "Reciver invalid xmlns:stream: #{attributes['xmlns:stream'].inspect}, should be #{Rim::Stream::Namespace.inspect}"
              close
              return
            end

            unless ['jabber:client', 'jabber:server'].include?(attributes['xmlns']) 
              Rim.logger.error "Reciver invalid xmlns #{attributes['xmlns'].inspect}, should be #{['jabber:client', 'jabber:server'].join(" or ")}"
              error('invalid-namespace')
              close
              return
            end

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
        
        def parse(tag,attributes)
          if tag == "auth"
            Rim.logger.info "Authenticating client using #{attributes["mechanism"]}"
            
            chellange = REXML::Element.new('challenge')
            chellange.add_namespace('urn:ietf:params:xml:ns:xmpp-sasl')
            chellange.text = "cmVhbG09InNvbWVyZWFsbSIsbm9uY2U9Ik9BNk1HOXRFUUdtMmhoIixxb3A9ImF1dGgiLGNoYXJzZXQ9dXRmLTgsYWxnb3JpdGhtPW1kNS1zZXNzCg=="
            write(chellange)
          end
        end
        
        def send_head(attr)
          Rim.logger.info "Sending header and feratures."
          
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
          
          feature = REXML::Element.new('stream:features')
          mech = REXML::Element.new('mechanisms')
          mech.add_namespace('urn:ietf:params:xml:ns:xmpp-sasl')
          
          ['PLAIN', 'DIGEST-MD5'].each do |con_type|
            mechxml = REXML::Element.new('mechanism')
            mechxml.text = con_type
            mech << mechxml
          end
          
          feature << mech
          
          write(feature)
        end
      end
    end
    
    def read(content)
      Rim.logger.debug content.blue
      @parser.source.buffer << content
      @parser.parse
      # parse(content)
      #self.send(:response, content) if respond_to?(:response)
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

      @parser.listen(:start_element) do |uri, localname, qname, attributes|
        self.send(:parse, qname, attributes) if respond_to?(:parse)
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
      self.connection.close_connection(true)
    end
  end
end