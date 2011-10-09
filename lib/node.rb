module Rim
  class Node < REXML::Element
    
    def is?(check_type)
      self.name == check_type.to_s
    end
    
    def have?(have_type)
      self.elements[have_type.to_s].present?
    end
    
  end
end