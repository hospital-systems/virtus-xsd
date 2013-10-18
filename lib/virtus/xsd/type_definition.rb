module Virtus
  module Xsd
    class TypeDefinition
      attr_reader :name, :options
      attr_reader :attributes
      attr_accessor :superclass

      def initialize(name, opts = {})
        @name = name
        @options = opts
        @attributes = {}
      end

      def [](attr_name)
        attributes[attr_name] || (superclass && superclass[attr_name])
      end

      def hash
        name.hash
      end

      def eql?(other)
        other.is_a?(Virtus::Xsd::TypeDefinition) && name == other.name
      end

      def base?
        options[:base]
      end

      alias_method :==, :eql?
    end
  end
end