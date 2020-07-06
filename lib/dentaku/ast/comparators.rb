require_relative './operation'

module Dentaku
  module AST
    class Comparator < Operation
      @@excel_mode = true

      def self.precedence
        5
      end

      def type
        :logical
      end

      def lr(context)
        l = left.value(context)
        r = right.value(context)
        if @@excel_mode
          if l.class != r.class
            if l.kind_of?(Integer) && r == ""
              r = 0
            elsif l == "" && r.kind_of?(Integer)
              l = 0
            end
          end
        end
        [l, r]
      end

      private

      def _value
        yield
      rescue ::ArgumentError => argument_error
        raise Dentaku::ArgumentError, argument_error.message
      rescue NoMethodError => no_method_error
        raise Dentaku::Error, no_method_error.message
      end

      def value(&block)
        _value(&block)
      end

      def excel_value(context)
        _value(){
          l, r = lr(context)
          l.send(operator, r)
        }
      end
    end

    class LessThan < Comparator
      def value(context = {})
        return excel_value(context) if @@excel_mode
        super() { left.value(context) < right.value(context) }
      end

      def operator
        return :<
      end
    end

    class LessThanOrEqual < Comparator
      def value(context = {})
        return excel_value(context) if @@excel_mode
        super() { left.value(context) <= right.value(context) }
      end

      def operator
        return :<=
      end
    end

    class GreaterThan < Comparator
      def value(context = {})
        return excel_value(context) if @@excel_mode
        super() { left.value(context) > right.value(context) }
      end

      def operator
        return :>
      end
    end

    class GreaterThanOrEqual < Comparator
      def value(context = {})
        return excel_value(context) if @@excel_mode
        super() { left.value(context) >= right.value(context) }
      end

      def operator
        return :>=
      end
    end

    class NotEqual < Comparator
      def value(context = {})
        return excel_value(context) if @@excel_mode
        super() { left.value(context) != right.value(context) }
      end

      def operator
        return :!=
      end
    end

    class Equal < Comparator
      def value(context = {})
        return excel_value(context) if @@excel_mode
        super() { left.value(context) == right.value(context) }
      end

      def operator
        return :==
      end
    end
  end
end
