module Rim
  class Query < Rim::Node
    def initialize
      super("query")
    end
    
    def discoInfo?
      attributes["xmlns"] == "http://jabber.org/protocol/disco#info"
    end
    
    def discoItems?
      attributes["xmlns"] == "http://jabber.org/protocol/disco#items"
    end
  end
end