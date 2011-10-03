module Rim
  def self.logger
    if @logger.nil?
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc { |severity, datetime, progname, msg|
        type = severity
        if type == "DEBUG"
          msg + "\n"
        else 
          type = type.bold
          "#{type} #{datetime.strftime("%T %D")}: #{msg}\n"
        end
        
      }
    end
    @logger
  end
  
  def self.start
    EventMachine.run do
      Signal.trap("INT")  { EventMachine.stop }
      Signal.trap("TERM") { EventMachine.stop }
      
      Rim.logger.info "Staring server..."
      EventMachine.start_server("localhost", 5222, Rim::Connection)
    end
  end
end