module Rim
  class Stream
    Server = 0x0
    Client = 0x1

    attr_accessor :connection, :type, :stream_id, :host
    
    state_machine :initial => :idle do
      before_transition :idle => :establish, :do => :send_head
      
      state :idle do
        
        def parse
          
        end
        
        def response(content)
          self.establish
        end
        
      end
      
      event :establish do
        transition :idle => :establish
      end
      
      state :establish do
        def response(content)
          self.establish
        end
      end
    end
    
    def read(content)
      Rim.logger.debug "Read: #{content}"
      # parse(content)
      self.send(:response, content) if respond_to?(:response)
    end
    
    def write(content)
      Rim.logger.debug "Sending: #{content}"
      self.connection.send_data(content)
    end
    
    def send_head
      self.stream_id = UUIDTools::UUID.timestamp_create
      connection_type = "jabber:client"
      stanza = %(<?xml version='1.0'?>) +
               %(<stream:stream ) +
               %(xmlns='#{connection_type}' ) +
               %(xmlns:stream='http://etherx.jabber.org/streams' ) +
               %(from='#{self.host}' ) +
               %(id='#{self.stream_id}' ) +
               %(version='1.0'>)

      write(stanza)
    end

    
    def initialize(host, connection)
      super()
      self.host = host
      self.connection = connection

    end
    
    def close
      write("</stream:stream>")
    end
  end
end