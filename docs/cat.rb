require 'pupa'

# All models should inherit from (or quack like) [Pupa::Base](https://github.com/opennorth/pupa-ruby/blob/master/lib/pupa/models/base.rb#files).
class Cat < Pupa::Base
  # If you would like Pupa.rb to validate your objects, assign to `self.schema`
  # an absolute path to a [JSON Schema](http://json-schema.org/). See for
  # example [Popolo's JSON Schema files](https://github.com/opennorth/pupa-ruby/tree/master/schemas/popolo).
  self.schema = '/path/to/json-schema/cat.json'

  # Adds the `created_at` and `updated_at` metadata properties from [Popolo](http://popoloproject.com/specs/).
  # `created_at` and `updated_at` will be set by Pupa.rb before writing to the
  # database. See [Pupa::Concerns](http://rdoc.info/gems/pupa/Pupa/Concerns)
  # for more mixins.
  include Pupa::Concerns::Timestamps

  # When converting an object to a hash with the `to_h` method (e.g. before
  # saving an object to disk), only the properties declared with `attr_accessor`
  # will be included in the hash.
  attr_accessor :image, :name, :breed, :age, :sex

  # Adds a `to_s` method so that it's easier to see which objects are being
  # saved in the processor's log.
  def to_s
    name
  end
end

# All processors should inherit from [Pupa::Processor](https://github.com/opennorth/pupa-ruby/blob/master/lib/pupa/processor.rb#files).
class CatProcessor < Pupa::Processor
  # For simple processors like this one, you may put all your code in a generic
  # `extract` method.
  def extract
    # The `get` and `post` helpers take a URL as a first argument, and a query
    # string or request body as a second argument.
    #
    # These methods return the parsed response if the response is HTML, XML or
    # JSON, and the raw response otherwise.
    #
    # Responses are by default cached for one day to avoid repeat requests while
    # developing and testing a processor.
    doc = post('http://www.iams.ca/en-ca/rescue-pets/adopt-a-pet',
      'petName=Cat&petLocation=H2Y 1C6&nextPetSeachFlag=true')

    # HTML responses are parsed by [Nokogiri](http://nokogiri.org/).
    doc.css('#show-result ul:gt(1)').each do |row|
      # Creates a new Cat object.
      cat = Cat.new

      # The `clean` helper removes extra whitespace from a string.
      cat.name = clean(row.at_css('.name').text)
      cat.breed, cat.age, cat.sex =
        clean(row.at_css('.features').text).split(', ')
      cat.photo = row.at_css('img')[:src]

      # Yields the Cat object to the transformation task for processing, e.g.
      # saving to disk, printing to CSV, etc.
      Fiber.yield(cat)
    end
  end
end

# Ready to move on? Check out the next example: [bill.rb](http://opennorth.github.io/pupa-ruby/docs/bill.html).
