module Rim
  
  def self.uid
    @uid ||= 0
    @uid += 1
    "rim_#{@uid}"
  end
  
  def self.logger
    if @logger.nil?
      @line_number = 0
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc { |severity, datetime, progname, msg|
        type = severity
        if type == "DEBUG"
          @line_number += 1
          sprintf("#{"%5d".bold.black_on_white} %s\n", @line_number, msg)
        elsif type == "WARN"
          ("WARN".bold.yellow + " #{msg.yellow}\n".yellow).yellow
        elsif type == "ERROR"
          ("ERROR".bold.red + " #{msg.red}\n".red).red
        else 
          type = type.bold
          "#{" #{type}".bold.black_on_white} #{datetime.strftime("%T %D")}: #{msg}\n"
        end
        
      }
    end
    @logger
  end
  
  def self.env
    :development
  end
  
  def self.config
    if @config.nil?
      yaml = YAML.load(File.open(Rim.config_path, 'r'))
      @config = OpenStruct.new(yaml)
    end
    @config
  end
  
  def self.config_path
    File.expand_path('./config/conf.yml')
  end
  
  def self.start
    Rim.logger.info "Starting server..."
    Rim.logger.info "Loading configuration: #{Rim.config_path}"
    Rim.config
    Mongoid.logger = Rim.logger
    Mongoid.load!("./config/mongoid.yml")
    
    Rim.logger.info "Running in env #{Rim.env}"
    
    Rim.logger.info "Connecting to database..."
    Mongoid.configure do |config|
      config.master = Mongo::Connection.new.db("rim")
    end
    User.create(:login => "test", :password => "password")

    EventMachine.run do
      Signal.trap("INT")  { EventMachine.stop }
      Signal.trap("TERM") { EventMachine.stop }
      
      Rim.logger.info "Staring server at: #{Rim.config.realm} on port #{Rim.config.port}"
      EventMachine.start_server(Rim.config.realm, Rim.config.port, Rim::Connection)
    end
  end
end
