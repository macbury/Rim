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
  
  def self.config
    if @config.nil?
      yaml = YAML.load(File.open('./config/conf.yml', 'r'))
      @config = OpenStruct.new(yaml)
    end
    @config
  end
  
  def self.start
    Rim.logger.info "Loading configuration"
    Rim.config
    Mongoid.logger = Rim.logger
    Mongoid.load!("./config/mongoid.yml")
    
    Rim.logger.info "Connecting to database..."
    Mongoid.configure do |config|
      config.master = Mongo::Connection.new.db("rim")
    end
    #User.create(:login => "test", :password => "password")
    EventMachine.run do
      Signal.trap("INT")  { EventMachine.stop }
      Signal.trap("TERM") { EventMachine.stop }
      
      Rim.logger.info "Staring server at: #{Rim.config.realm} on port #{Rim.config.port}"
      EventMachine.start_server(Rim.config.realm, Rim.config.port, Rim::Connection)
    end
  end
end