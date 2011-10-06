module Rim
  class Connection < EM::Connection
    @@clients = []
    attr_accessor :stream
    def post_init
      port, ip = Socket.unpack_sockaddr_in(get_peername)
      Rim.logger.info "New connection: #{ip}"
      
      #start_tls
      @stream = Rim::Stream.new("localhost",self)
      @@clients << self
    end
    
    def stream
      @stream
    end
    
    def receive_data(data)
      @stream.read(data)
    end
    
    def find_by_jid(jid)
      @@clients.reject_if { |client| client == self }
    end
    
    def unbind
      Rim.logger.info "Client disconnected."
      @@clients.delete(self)
    end
  end
end