require 'pupa'

# The [cat.rb](https://github.com/opennorth/pupa-ruby/blob/master/docs/cat.html)
# example goes over the basics of using Pupa.rb. This example covers some more
# advanced topics.

# Define a new class to model legislative bills.
class Bill < Pupa::Base
  self.schema = '/path/to/json-schema/bill.json'

  # Add the `sources`, `created_at` and `updated_at` properties from Popolo.
  include Pupa::Metadata

  # In this example, we will simply extract the names of bills and associate
  # each bill with a sponsor and legislative body, e.g. the House of Commons.
  attr_accessor :name, :sponsor_id, :organization_id

  # @todo match with existing person
  def sponsor=(sponsor)
    @sponsor = sponsor
  end

  # @todo match with existing organization
  def organization=(organization)
    @organization = organization
  end

  def to_s
    name
  end
end

# Register an extraction (scraping) task. This defines a `bills` method on each
# processor, which returns a lazy enumerator of all Bill objects extracted by
# that processor. Pupa.rb already registers extraction tasks for people,
# organizations, memberships and posts.
Pupa::Processor.add_extract_task(:bills)

# Scrape legislative information about the Parliament of Canada.
class HouseOfCommonsOfCanada < Pupa::Processor
  # Instead of defining a single `extract` method to perform all extraction, we
  # define an extraction task for each type of data we want to extract: people,
  # organizations and bills.
  #
  # This allows us to, for example, run each extraction task on a different
  # schedule. Bill data is updated more frequently than person data; we would
  # therefore run the bills task more frequently.
  #
  # See the [`extract_task_method`](https://github.com/opennorth/pupa-ruby/blob/master/lib/pupa/scraper.rb#L108)
  # documentation for more information on the naming of these methods.
  def extract_people
    doc = get('http://www.parl.gc.ca/MembersOfParliament/MainMPsCompleteList.aspx?TimePeriod=Current&Language=E')
    doc.css('#MasterPage_MasterPage_BodyContent_PageContent_Content_ListContent_ListContent_grdCompleteList tr:gt(1)').each do |row|
      person = Pupa::Person.new
      person.name = row.at_css('td:eq(1)').text.match(/\A([^,]+?), ([^(]+?)(?: \(.+\))?\z/)[1..2].
        reverse.map{|component| component.strip.squeeze(' ')}
      Fiber.yield(person)
    end
  end

  # Hardcode the top-level organizations within the Parliament of Canada.
  def extract_organizations
    parliament = Pupa::Organization.new(name: 'Parliament of Canada')
    Fiber.yield(parliament)

    house_of_commons = Pupa::Organization.new(name: 'House of Commons', parent: parliament)
    Fiber.yield(house_of_commons)

    senate = Pupa::Organization.new(name: 'Senate', parent: parliament)
    Fiber.yield(senate)
  end

  # Associate each bill with a sponsor and a legislative body.
  def extract_bills
    doc = get('http://www.parl.gc.ca/LegisInfo/Home.aspx?language=E&ParliamentSession=41-1&Mode=1&download=xml')
    doc.xpath('//Bill').each do |row|
      bill = Bill.new
      bill.name = row.at_xpath('./BillTitle/Title[@language="en"]').text
      # @todo docs
      bill.sponsor = {
        name: row.at_xpath('./SponsorAffiliation/Person/FullName').text,
      }
      bill.organization = {
        name: row.at_xpath('./BillNumber/@prefix').value == 'C' ? 'House of Commons' : 'Senate',
      }
      Fiber.yield(bill)
    end
  end
end
