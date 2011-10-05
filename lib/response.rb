module Rim
  class Response
    attr_accessor :xmlns, :body, :done
    
    def tag_start(name, attrs)
      if name == "response"
        xmlns = attrs["xmlns"]
      end
    end
    
    def text(new_content)
      body ||= ""
      body += new_content 
    end
    
    def content
      Base64.decode64(body)
    end
    
    def tag_end(name)
      if name == "response"
        done = true
      end
    end
  end
end