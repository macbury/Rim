module Rim
  class Connection < EM::Connection
    def post_init
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      Rim.logger.info "New connection: #{ip}"
      @parser = Rim::StreamParser.new
    end
    
    def receive_data(data)
      REXML::Document.parse_stream( data, @parser ) rescue nil
      
      return unless @parser.done
      if @parser.server
        Rim.logger.info "Server stream started..."
      else
        Rim.logger.info "Client stream started..."
        @myhost="localhost"
        @id = "2"
        stanza = %(<?xml version='1.0'?>) +
                 %(<stream:stream ) +
                 %(xmlns='jabber:client' ) +
                 %(xmlns:stream='http://etherx.jabber.org/streams' ) +
                 %(from='#{@myhost}' ) +
                 %(id='#{@id}' ) +
                 %(version='1.0'>)
        Rim.logger.info stanza
        send_data(stanza)
        
        send_data "<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
           
      end
    end
  end
end