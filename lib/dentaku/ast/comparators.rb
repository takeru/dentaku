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
    end

    class LessThan < Comparator
      def value(context={})
        l, r = lr(context)
        l < r
      end
    end

    class LessThanOrEqual < Comparator
      def value(context={})
        l, r = lr(context)
        l <= r
      end
    end

    class GreaterThan < Comparator
      def value(context={})
        l, r = lr(context)
        l > r
      end
    end
    class GreaterThanOrEqual < Comparator
      def value(context={})
        l, r = lr(context)
        l >= r
      end
    end

    class NotEqual < Comparator
      def value(context={})
        l, r = lr(context)
        l != r
      end
    end

    class Equal < Comparator
      def value(context={})
        l, r = lr(context)
        l == r
      end
    end
  end
end
