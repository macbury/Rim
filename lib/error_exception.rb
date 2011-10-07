module Rim
  
  class ErrorException < RuntimeError

    def initialize(stanza, defined_condition, type)
      @node = REXML::Element.new(stanza.name)
      @node.add_attribute('type', 'error')
      @node.add_attribute('id', stanza.attributes['id'])
  
      err = REXML::Element.new('error')
      err.add_attribute('type', type)
  
      cond = REXML::Element.new(defined_condition)
      cond.add_namespace('urn:ietf:params:xml:ns:xmpp-stanzas')
  
      err << cond
      @node << err
    end
    
    def xml
      @node
    end
    
  end
  
end