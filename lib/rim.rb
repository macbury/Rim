module Rim
  def self.logger
    if @logger.nil?
      @line_number = 0
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc { |severity, datetime, progname, msg|
        type = severity
        if type == "DEBUG"
          @line_number += 1
          sprintf("#{"%5d".bold} %s\n", @line_number, msg)
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