require 'forwardable'

require 'active_support/concern'
require 'active_support/inflector'

require 'pupa/logger'
require 'pupa/processor'
require 'pupa/runner'

require 'pupa/models/concerns/contactable'
require 'pupa/models/concerns/identifiable'
require 'pupa/models/concerns/linkable'
require 'pupa/models/concerns/metadata'
require 'pupa/models/concerns/nameable'

require 'pupa/models/base'
require 'pupa/models/contact_detail_list'
require 'pupa/models/membership'
require 'pupa/models/organization'
require 'pupa/models/person'
require 'pupa/models/post'

module Pupa
  class Error < StandardError; end

  class << self
    attr_accessor :session
  end
end

Pupa::Processor.add_extract_task(:memberships)
Pupa::Processor.add_extract_task(:organizations)
Pupa::Processor.add_extract_task(:people)
Pupa::Processor.add_extract_task(:posts)
