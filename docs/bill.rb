# The [cat.rb](http://opennorth.github.io/pupa-ruby/docs/cat.html) example goes
# over the basics of using Pupa.rb. This covers how to relate objects and how to
# separate scraping tasks for different types of data.
require 'pupa'

# Defines a new class to model legislative bills. In this example, we will
# simply scrape the names of bills and associate each bill with a sponsor and a
# legislative body.
class Bill < Pupa::Base
  attr_accessor :name, :sponsor_id, :organization_id, :sponsor, :organization

  # When saving scraped objects to a database, these foreign keys will be used
  # to derive an evaluation order.
  foreign_key :sponsor_id, :organization_id

  # Sometimes, you may not know the ID of an existing foreign object, but you
  # may have other information to identify it. In that case, put the information
  # you have in a property named after the foreign key without the `_id` suffix:
  # for example, `sponsor` for `sponsor_id`. Before saving the object to the
  # database, Pupa.rb will use this information to identify the foreign object.
  foreign_object :sponsor, :organization

  # Overrides the `sponsor=` setter to automatically add the `_type` property,
  # instead of having to add it each time in the processor.
  def sponsor=(sponsor)
    @sponsor = {'_type' => 'pupa/person'}.merge(sponsor)
  end

  def organization=(organization)
    @organization = {'_type' => 'pupa/organization'}.merge(organization)
  end

  def fingerprint
    to_h.slice(:name, :organization_id)
  end

  def to_s
    name
  end
end

# Scrapes legislative information about the Parliament of Canada.
class ParliamentOfCanada < Pupa::Processor
  # Instead of defining a single `scrape_objects` method to perform all the
  # scraping, we define a scraping task for each type of data we want to scrape:
  # people, organizations and bills.
  #
  # This will let us later, for example, run each task on a different schedule.
  # Bill data is updated more frequently than person data; we would therefore
  # run the bills task more frequently.
  #
  # See the [`scraping_task_method`](https://github.com/opennorth/pupa-ruby/blob/master/lib/pupa/processor.rb#L158)
  # documentation for more information on the naming of scraping methods.
  def scrape_people
    doc = get('http://www.parl.gc.ca/MembersOfParliament/MainMPsCompleteList.aspx?TimePeriod=Historical&Language=E')
    doc.css('#MasterPage_MasterPage_BodyContent_PageContent_Content_ListContent_ListContent_grdCompleteList tr:gt(1)').each do |row|
      person = Pupa::Person.new
      person.name = row.at_css('td:eq(1)').text.match(/\A([^,]+?), ([^(]+?)(?: \(.+\))?\z/)[1..2].
        reverse.map{|component| component.strip.squeeze(' ')}.join(' ')
      # Some bills omit sponsors' middle names, so we add an alternate name that
      # omits any middle names.
      components = person.name.split(' ')
      person.add_name("#{components.first} #{components.last}")
      Fiber.yield(person)
    end
  end

  # Hardcodes the top-level organizations within Parliament.
  def scrape_organizations
    parliament = Pupa::Organization.new(name: 'Parliament of Canada')
    Fiber.yield(parliament)

    house_of_commons = Pupa::Organization.new(name: 'House of Commons', parent_id: parliament._id)
    Fiber.yield(house_of_commons)

    senate = Pupa::Organization.new(name: 'Senate', parent_id: parliament._id)
    Fiber.yield(senate)
  end

  def scrape_bills
    doc = get('http://www.parl.gc.ca/LegisInfo/Home.aspx?language=E&ParliamentSession=41-1&Mode=1&download=xml')
    doc['Bills']['Bill'].each do |row|
      # Skip Senate bills, since we currently only scrape Members of Parliament.
      next if row['BillNumber']['prefix'] == 'S'

      bill = Bill.new
      bill.name = row['BillTitle']['Title'].find{|x| x['language'] == 'en'}['__content__']
      # Here, we tell the Bill everything we know about the sponsor and the
      # legislative body. Pupa.rb will later determine which objects match the
      # given information.
      name = row['SponsorAffiliation']['Person']['FullName']
      bill.sponsor = {
        '$or' => [
          {'name' => name},
          {'other_names.name' => name},
        ],
      }
      bill.organization = {
        name: row['BillNumber']['prefix'] == 'C' ? 'House of Commons' : 'Senate',
      }
      Fiber.yield(bill)
    end
  end
end

ParliamentOfCanada.add_scraping_task(:bills)
ParliamentOfCanada.add_scraping_task(:organizations)
ParliamentOfCanada.add_scraping_task(:people)

# By default, if you run `bill.rb`, it will perform all scraping tasks and
# import all the scraped objects into the database. Use the `--action` and
# `--task` switches to control the processor's behavior.
runner = Pupa::Runner.new(ParliamentOfCanada)
runner.run(ARGV)

# Ready for more? Check out the next example: [legislator.rb](http://opennorth.github.io/pupa-ruby/docs/legislator.html).
