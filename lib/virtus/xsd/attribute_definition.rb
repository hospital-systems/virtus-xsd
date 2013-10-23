module Virtus
  module Xsd
    class AttributeDefinition
      attr_reader :name, :type, :options

      def initialize(name, type_definition, opts = {})
        @name = name
        @type = type_definition
        @options = opts
      end

      def multiple?
        options[:multiple]
      end
    end
  end
end