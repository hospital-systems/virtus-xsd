require 'virtus/xsd/generation/ruby_code_builder'
require 'active_support/core_ext/string/inflections'

module Virtus
  module Xsd
    class RubyGenerator
      def initialize(type_definitions, opts = {})
        @type_definitions = type_definitions
        @options = opts
      end

      def generate_classes
        @type_definitions.each { |type_definition| generate_class(type_definition) }
      end

      private

      def generate_class(type_def)
        return if type_def.base? || type_def.simple?
        output_for(type_def) do |output|
          builder = Generation::RubyCodeBuilder.new(output)
          builder.class_(get_sanitized_type_name(type_def),
                         superclass: type_def.superclass && get_sanitized_type_name(type_def.superclass),
                         module_name: module_name) do
            builder.invoke_pretty 'include', 'Virtus.model'
            builder.blank_line
            type_def.attributes.values.sort_by(&:name).each do |attr|
              builder.invoke_pretty 'attribute',
                                    ":#{make_attribute_name(attr)}", make_attribute_type(attr)
            end
          end
        end
      end

      def make_attribute_name(attr)
        attr.name.underscore
      end

      def make_attribute_type(attr)
        type_name = make_type_name(attr.type)
        attr.multiple? ? "Array[#{type_name}]" : type_name
      end

      def make_type_name(type)
        return get_sanitized_type_name(type) if type.base?
        if type.item_type
          "Array[#{make_type_name(type.item_type)}]"
        else
          type.simple? ? make_type_name(type.superclass) : get_sanitized_type_name(type)
        end
      end

      def get_sanitized_type_name(type)
        type.name.split(/\.|_/).map(&:camelcase).join('_')
      end

      def output_for(type_definition)
        file_path = generate_file_name(type_definition)
        FileUtils.mkdir_p(File.dirname(file_path))
        output = File.new(file_path, 'w')
        yield output
      ensure
        output.close if output
      end

      def generate_file_name(type_definition)
        module_path = (module_name || '').underscore.split('/')
        File.join(output_dir, *module_path, "#{get_sanitized_type_name(type_definition).underscore}.rb")
      end

      def output_dir
        @options[:output_dir]
      end

      def module_name
        @options[:module_name]
      end
    end
  end
end