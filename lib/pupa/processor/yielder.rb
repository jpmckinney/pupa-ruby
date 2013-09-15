# Using fibers instead of enumerators leads to less coupling in the processor.
# @see https://practicingruby.com/articles/building-enumerable-and-enumerator?u=dc2ab0f9bb
require 'fiber'

module Pupa
  class Processor
    # A lazy enumerator.
    class Yielder
      # The given block should yield objects to add to the enumerator.
      def initialize
        @fiber = Fiber.new do
          yield
          raise StopIteration
        end
      end

      # Yields each object in the enumerator to the given block.
      def each
        if block_given?
          loop do
            yield self.next
          end
        else
          to_enum
        end
      end

      # Returns the next object in the enumerator, and moves the internal position
      # forward. When the position reaches the end, `StopIteration` is raised.
      def next
        if @fiber.alive?
          @fiber.resume
        else
          raise StopIteration
        end
      end

      # Returns a lazy enumerator.
      #
      # @return [Enumerator] a lazy enumerator
      def to_enum
        Enumerator.new do |y|
          loop do
            y << self.next
          end
        end
      end
    end
  end
end
