require 'forwardable'
require 'json'

require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/blank'
require 'active_support/inflector'

require 'mail'

require 'pupa/models/concerns/indifferent_access'
require 'pupa/models/concerns/contactable'
require 'pupa/models/concerns/identifiable'
require 'pupa/models/concerns/linkable'
require 'pupa/models/concerns/nameable'
require 'pupa/models/concerns/sourceable'
require 'pupa/models/concerns/timestamps'

require 'pupa/errors'
require 'pupa/logger'
require 'pupa/processor'
require 'pupa/runner'

require 'pupa/models/foreign_object'
require 'pupa/models/model'
require 'pupa/models/contact_detail_list'
require 'pupa/models/identifier_list'
require 'pupa/models/area'
require 'pupa/models/membership'
require 'pupa/models/motion'
require 'pupa/models/organization'
require 'pupa/models/person'
require 'pupa/models/post'
require 'pupa/models/vote'
require 'pupa/models/vote_event'

module Pupa
end

# ActiveSupport's String methods become bottlenecks once:
#
# - HTTP responses are cached in Memcached
# - JSON documents are dumped to Redis
# - Redis is pipelined
# - Validation is skipped
# - The runner is quiet
#
# With these optimizations, in sample scripts, garbage collection and gem
# requiring take up two-thirds of the running time.
class String
  # Alternatively, check if `inflections.acronym_regex` is equal to `/(?=a)b/`.
  # If so, to skip the substitution, which is guaranteed to fail.
  #
  # @see http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-underscore
  def underscore
    word = gsub('::', '/')
    # word.gsub!(/(?:([A-Za-z\d])|^)(#{inflections.acronym_regex})(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end

  # @see http://api.rubyonrails.org/classes/String.html#method-i-blank-3F
  alias_method :blank?, :empty?
end

# @see https://github.com/ruby-json-schema/json-schema/tree/master/lib/json-schema/attributes/formats
JSON::Validator.register_format_validator('email', lambda{|data|
  return unless data.is_a?(String)
  address = Mail::Address.new(data)
  unless address.address == data && address.domain && address.domain.split('.').size > 1
    raise JSON::Schema::CustomFormatError.new("must be a valid email address (#{data})")
  end
})

JSON::Validator.register_format_validator('uri', lambda{|data|
  return unless data.is_a?(String)
  re = URI::DEFAULT_PARSER.regexp[:ABS_URI]
  unless re.match(data)
    raise JSON::Schema::CustomFormatError.new("must be a valid email URI (#{data})")
  end
})