
module Rim
  def self.logger
    if @logger.nil?
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc { |severity, datetime, progname, msg|
        date = datetime.strftime("%T %D") + ": "
        "#{date} #{msg}\n"
      }
    end
    @logger
  end
  
  def self.start
    EventMachine.run do
      Signal.trap("INT")  { EventMachine.stop }
      Signal.trap("TERM") { EventMachine.stop }
      
      Rim.logger.info "Staring server..."
      EventMachine.start_server("0.0.0.0", 5222, Rim::Connection)
    end
  end
end
