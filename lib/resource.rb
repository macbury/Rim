module Rim
  class Resource
    attr_accessor :name
    
    def initialize(name)
      self.name = name
    end
    
    def self.parse(elem)
      bind = elem.root.elements['bind']
      
      unless elem.has_elements?
        resource = Rim::Stream.uid
        resource = resource[0, 1023]
      else
        resource = bind.elements['resource'].text[0, 1023]

        unless resource
          raise Rim::ErrorException.new(bind, 'bad-request', 'modify')
        end
      end
      
      Resource.new(resource)
      
    end
  end
end