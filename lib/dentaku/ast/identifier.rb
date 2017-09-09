require_relative '../exceptions'

module Dentaku
  module AST
    class Identifier < Node
      @@excel_mode = true
      @@enable_value_cache = true

      attr_reader :identifier

      def initialize(token)
        @identifier = token.value.downcase
      end

      def value(context={})
        v = context.fetch(identifier) do
          if @@excel_mode
            ""
          else
            raise UnboundVariableError.new([identifier]),
                  "no value provided for variables: #{identifier}"
          end
        end

        case v
        when Node
          if @@enable_value_cache
            context[identifier] = v.value(context)
          else
            v.value(context)
          end
        else
          v
        end
      end

      def dependencies(context={})
        context.key?(identifier) ? dependencies_of(context[identifier]) : [identifier]
      end

      private

      def dependencies_of(node)
        node.respond_to?(:dependencies) ? node.dependencies : []
      end
    end
  end
end
