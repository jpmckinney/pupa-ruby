require 'fiber'

module Pupa
  # Using fibers instead of enumerators leads to less coupling in the scraper.
  # @see https://practicingruby.com/articles/building-enumerable-and-enumerator?u=dc2ab0f9bb
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
      loop do
        yield self.next
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
  end
end
