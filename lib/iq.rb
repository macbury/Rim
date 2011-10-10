module Rim
  class IQ < Rim::Node
    
    def initialize
      super("iq")
    end
    
    def session?
      have?(:session)
    end
    
    def bind?
      have?(:bind)
    end

    def query?
      have?(:query)
    end

    def type=(new_type)
      add_attribute('type', new_type.to_s)
    end
    
    def type
      attributes['type'].to_sym
    end
    
    def id=(new_id)
      add_attribute('id', new_id)
    end
    
    def id
      attributes['id']
    end
    
    def make_result
      self.type = :result
      self
    end
    
    def query
      self.elements["query"]
    end
    
  end
end