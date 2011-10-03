module Rim
  class Connection < EM::Connection
    
    def post_init
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      Rim.logger.info "New connection: #{ip}"
      
      #start_tls
      @stream = Rim::Stream.new("localhost",self)
    end
    
    def receive_data(data)
      @stream.read(data)
    end
    
    def unbind
      Rim.logger.info "Client disconnected."
    end
  end
end