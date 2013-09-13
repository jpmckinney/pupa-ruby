require 'tsort'

module Pupa
  # A simple implementation of a dependency graph.
  #
  # @see http://ruby-doc.org/stdlib-2.0.0/libdoc/tsort/rdoc/TSort.html
  class DependencyGraph < Hash
    include TSort

    alias tsort_each_node each_key

    def tsort_each_child(node, &block)
      fetch(node).each(&block)
    end
  end
end
