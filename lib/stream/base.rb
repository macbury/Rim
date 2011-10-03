module Rim::Stream
  class Base
    
    def xmldecl(version, encoding, standalone)
      Rim.logger.debug "Stream start: #{version}:#{encoding}>"
    end
    
    def tag_start( name, attributes )
      Rim.logger.debug "<#{name} #{attributes.map {|k,v| "#{k}=#{v}" }.join(" ")}>"
    end
  
    def text( str )
      Rim.logger.debug(str)
    end
  
    def tag_end( name )
      Rim.logger.debug "</#{name}>"
    end
  end
  
end