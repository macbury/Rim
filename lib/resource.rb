module Rim
  class Resource
    attr_accessor :name, :resource_id
    
    def initialize(name)
      self.name = name
      self.resource_id = nil
    end
    
    def self.parse(elem)
      bind = elem.root.elements['bind']
      resource = bind.elements['resource']

      unless bind.attributes['xmlns'] == 'urn:ietf:params:xml:ns:xmpp-bind'
        raise Rim::ErrorException.new(bind, 'service-unavailable', 'cancel')
      end
  
      # Do they have too many connected already?
      #recs = DB::User.users[@jid].resources
      #if recs and recs.length > 10
      #    write Stanza.error(stanza, 'resource-constraint', 'cancel')
      #    return self
      #end
  
      # Does this stream already have a resource?
      # We currently do not support multiple bindings.
      #unless @resource.nil?
      #  write Stanza.error(stanza, 'not-allowed', 'cancel')
      #  return self
      #end
      
      if resource.nil?
        resource = Rim::Stream.uid
        resource = resource[0, 1023]
      else
        resource = resource.text[0, 1023]
        
        if resource.nil?
          raise Rim::ErrorException.new(bind, 'bad-request', 'modify')
        end
      end
      
      r = Resource.new(resource)
      r.resource_id = elem.attributes["id"]
      r
    end
    
    def success(jid_name)
      iq = REXML::Element.new("iq")
      iq.add_attributes({'id' => self.resource_id, 'type' => "result"})
      bind = REXML::Element.new('bind')
      bind.add_namespace('urn:ietf:params:xml:ns:xmpp-bind')
  
      jid = REXML::Element.new('jid')
      jid.text = jid_name + '/' + self.name
  
      bind << jid
      iq << bind
      iq
    end
  end
end