module Rim
  
  class FailureException < RuntimeError

    def initialize(msg, namespace)
      @node = REXML::Element.new('failure')
      @node.add_namespace(namespace)
      @node << REXML::Element.new(msg)
    end
    
    def xml
      @node
    end
    
    def self.not_authorized(namespace)
      FailureException.new("not-authorized", namespace)
    end
  end
  
end