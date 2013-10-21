module Virtus
  module Xsd
    class Parser
      module Queries
        def find_attribute_or_element_by_name(name)
          (scope.attributes + scope.elements).xpath("self::*[@name=\"#{name}\"]").first
        end
      end
    end
  end
end