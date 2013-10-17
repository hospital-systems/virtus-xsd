module Virtus
  module Xsd
    module Generation
      class RubyClassBuilder
        def initialize(output)
          @output = output
          @identation = ''
        end

        def module_(name)
          parts = name.split('::', 2)
          build_module(parts[0]) do
            if (sub_module_name = parts[1])
              module_(sub_module_name) { yield }
            else
              yield
            end
          end
        end

        def class_(name, opts = {})
          if (module_name = opts[:module_name])
            module_(module_name) { build_class(name, opts[:superclass]) { yield } }
          else
            build_class(name, opts[:superclass]) { yield }
          end
        end

        def invoke_pretty(method_name, *args)
          build_line "#{method_name} #{args.join(', ')}"
        end

        def blank_line
          build_line ''
        end

        def ident
          saved_identation, @identation = @identation, @identation + '  '
          yield
        ensure
          @identation = saved_identation
        end

        private

        def build_module(name)
          build_line "module #{name}"
          ident { yield }
          build_line 'end'
        end

        def build_class(name, superclass = nil)
          build_line "class #{[name, superclass].compact.join(' < ')}"
          ident { yield }
          build_line 'end'
        end

        def build_line(line)
          @output.print @identation
          @output.puts line
        end
      end
    end
  end
end