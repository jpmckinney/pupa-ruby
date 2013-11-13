module Pupa::Model
  # This unfortunately won't cause the behavior of any model that has already
  # included `Pupa::Model` to change.
  class << self
    def append_features(base)
      if base.instance_variable_defined?("@_dependencies")
        base.instance_variable_get("@_dependencies") << self
        return false
      else
        return false if base < self
        @_dependencies.each { |dep| base.send(:include, dep) }
        super
        base.extend const_get("ClassMethods") if const_defined?("ClassMethods")
        base.class_eval(&@_included_block) if instance_variable_defined?("@_included_block")
        base.class_eval do # XXX
          set_callback(:save, :before) do |object|
            object._type = object._type.camelize.demodulize.underscore
          end
        end
      end
    end
  end
end

# `set_callback` is called by `class_eval` in `ActiveSupport::Concern`. Without
# monkey-patching `ActiveSupport::Concern`, we can either iterate `ObjectSpace`,
# implement something like ActiveSupport's `DescendantsTracker` for inclusion
# instead of inheritance, or go back to `Pupa::Model` being a superclass instead
# of a mixin to take advantage of `DescendantsTracker` itself.
#
# Instead of adding a callback, we can override `to_h`, but that is harder to
# maintain and less future-proof. We can also implement a non-callback hook in
# `Persistence`, but that will not be of general interest.
ObjectSpace.each_object(Class) do |base|
  if base.include?(Pupa::Model)
    base.class_eval do
      set_callback(:save, :before) do |object|
        object._type = object._type.camelize.demodulize.underscore
      end
    end
  end
end
