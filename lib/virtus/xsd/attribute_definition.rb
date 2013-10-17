module Virtus
  module Xsd
    class AttributeDefinition
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end
  end
end