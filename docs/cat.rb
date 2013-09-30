require 'pupa'

# Require Nokogiri so that HTML responses are automatically parsed.
require 'nokogiri'

class Cat
  # All models should mixin
  #[Pupa::Model](https://github.com/opennorth/pupa-ruby/blob/master/lib/pupa/models/model.rb#files).
  include Pupa::Model

  # If you would like Pupa.rb to validate your objects, assign to `self.schema`
  # an absolute path to a [JSON Schema](http://json-schema.org/). See for
  # example [Popolo's JSON Schema files](https://github.com/opennorth/pupa-ruby/tree/master/schemas/popolo).
  # self.schema = '/path/to/json-schema/cat.json'

  # Adds the `created_at` and `updated_at` metadata properties from [Popolo](http://popoloproject.com/specs/).
  # `created_at` and `updated_at` will be set by Pupa.rb before writing to the
  # database. See [Pupa::Concerns](http://rdoc.info/gems/pupa/Pupa/Concerns)
  # for more mixins.
  include Pupa::Concerns::Timestamps

  attr_accessor :image, :name, :breed, :age, :sex

  # Declares which properties should be dumped to JSON after a scraping task is
  # complete. All of these properties will be imported to MongoDB.
  dump :image, :name, :breed, :age, :sex

  # When saving an object to the database, Pupa.rb will check if the object had
  # been saved in a previous run. It uses a "fingerprint" of the object: a
  # subset of the object's properties that should uniquely identify the object
  # within the context of the scraping task. In this case, the image is not an
  # identifying property, because the image can change without changing the cat.
  def fingerprint
    to_h.slice(:name, :breed, :age, :sex)
  end

  # Adds a `to_s` method so that it's easier to see which objects are being
  # saved in the processor's log.
  def to_s
    name
  end
end

# All processors should inherit from [Pupa::Processor](https://github.com/opennorth/pupa-ruby/blob/master/lib/pupa/processor.rb#files).
class CatProcessor < Pupa::Processor
  # For simple processors like this one, you may put all your code in a generic
  # `scrape_objects` method.
  def scrape_objects
    # The `get` and `post` helpers take a URL as a first argument, and a query
    # string or request body as a second argument.
    #
    # These methods return the parsed response if the response is HTML, XML or
    # JSON, and the raw response otherwise.
    #
    # Responses are by default cached for one day to avoid repeat requests while
    # developing and testing a processor.
    doc = post('http://www.iams.ca/en-ca/rescue-pets/pet-finder',
      'petName=Cat&petLocation=H2Y 1C6&nextPetSeachFlag=true')

    # HTML responses are parsed by [Nokogiri](http://nokogiri.org/).
    doc.css('#show-result ul:gt(1)').each do |row|
      # Skips multiple unnamed kittens. Only individual cats!
      next if clean(row.at_css('.name').text) == 'Chatons pour adoption'

      # Creates a new Cat object.
      cat = Cat.new

      # The `clean` helper removes extra whitespace from a string.
      cat.image = row.at_css('img')[:src]
      cat.name = clean(row.at_css('.name').text)
      cat.breed, cat.age, cat.sex =
        clean(row.at_css('.features').text).split(', ')

      # Yields the Cat object to the transformation task for processing, e.g.
      # saving to disk, printing to CSV, etc.
      dispatch(cat)
    end
  end
end

# Registers a scraping task. This will define an `objects` method on the
# processor, which will return a lazy enumerator of all objects scraped by the
# processor.
CatProcessor.add_scraping_task(:objects)

# Tells the Pupa command-line parser which processor to use, and then parses
# command-line options. Run `cat.rb --help` to see a full list of options.
runner = Pupa::Runner.new(CatProcessor)
runner.run(ARGV)

# Ready to move on? Check out the next example: [bill.rb](http://opennorth.github.io/pupa-ruby/docs/bill.html).
