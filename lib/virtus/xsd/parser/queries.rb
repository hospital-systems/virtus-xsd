module Virtus
  module Xsd
    class Parser
      module Queries
        def find_attribute_or_element_by_name(name)
          parts = name.split(':')
          parts.unshift(nil) if parts.length == 1
          ns, local_name = parts
          scope = ns ? self.scope[ns] : self.scope
          (scope.attributes + scope.elements).xpath("self::*[@name=\"#{local_name}\"]").first
        end
      end
    end
  end
end