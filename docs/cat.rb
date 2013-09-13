require 'pupa'

# All models should inherit from (or quack like) [Pupa::Base](https://github.com/opennorth/pupa-ruby/blob/master/lib/pupa/models/base.rb).
class Cat < Pupa::Base
  # If you would like Pupa.rb to validate your objects, assign to `self.schema`
  # an absolute path to a [JSON Schema](http://json-schema.org/). You may want
  # to consult [Popolo's JSON Schema files](https://github.com/opennorth/pupa-ruby/tree/master/schemas/popolo).
  self.schema = '/path/to/json-schema/cat.json'

  # When converting an object to a hash using the `to_h` method (e.g. when
  # saving an object to disk), only the properties declared with `attr_accessor`
  # will be included in the hash.
  attr_accessor :image, :name, :breed, :age, :sex

  # Add a `to_s` method so that it is easier to see which objects are being
  # saved in the processor's log.
  def to_s
    name
  end
end

# All processors should inherit from [Pupa::Processor](https://github.com/opennorth/pupa-ruby/blob/master/lib/pupa/processor.rb).
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
      # Create a new Cat object.
      cat = Cat.new

      # The `clean` helper removes extra whitespace from a string.
      cat.name = clean(row.at_css('.name').text)
      cat.breed, cat.age, cat.sex =
        clean(row.at_css('.features').text).split(', ')
      cat.photo = row.at_css('img')[:src]

      # Yield the Cat object to the transformation task for processing, e.g.
      # saving to disk, printing to CSV, etc.
      Fiber.yield(cat)
    end
  end
end
