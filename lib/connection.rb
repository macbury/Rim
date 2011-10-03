module Rim
  class Connection < EM::Connection
    def post_init
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      Rim.logger.info "New connection: #{ip}"
      @stream = Rim::Stream.new("localhost",self)
    end
    
    def receive_data(data)
      @stream.read(data)
    end
  end
end