module Pupa
  module Errors
    # An abstract class from which all Pupa errors inherit.
    class Error < StandardError; end

    # This error is raised when saving an object to a database if a foreign key
    # cannot be resolved.
    class MissingDatabaseIdError < Error; end

    # This error is raised when dumping extracted objects to disk if two of
    # those objects share an ID.
    class DuplicateObjectIdError < Error; end

    # This error is raised when attempting to get or set a property that does
    # not exist in an object.
    class MissingAttributeError < Error; end

    # This error is raised when saving an object to a database if the object
    # matches more than one document in the database.
    class TooManyMatches < Error; end
  end
end
