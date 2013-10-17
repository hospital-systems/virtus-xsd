module Virtus
  module Xsd
    class TypeDefinition
      attr_reader :name
      attr_reader :attributes

      def initialize(name)
        @name = name
        @attributes = {}
      end

      def [](attr_name)
        attributes[attr_name]
      end

      def hash
        name.hash
      end

      def eql?(other)
        other.is_a?(Virtus::Xsd::TypeDefinition) && name == other.name
      end

      alias_method :==, :eql?
    end
  end
end