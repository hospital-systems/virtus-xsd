module Virtus
  module Xsd
    class AttributeDefinition
      attr_reader :name, :type

      def initialize(name, type_definition)
        @name = name
        @type = type_definition
      end
    end
  end
end