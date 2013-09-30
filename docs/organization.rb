# The [cat.rb](http://opennorth.github.io/pupa-ruby/docs/cat.html),
# [bill.rb](http://opennorth.github.io/pupa-ruby/docs/bill.html) and
# [legislator.rb](http://opennorth.github.io/pupa-ruby/docs/legislator.html)
# examples show you how to scrape and import data. This example shows you how
# to transform scraped data.
require 'pupa'

require 'csv'

# We're going to scrape organizations and output them as CSV, which we can then
# upload to the [Open Knowledge Foundation](https://github.com/okfn/publicbodies)'s
# [Public Bodies](http://publicbodies.org/) project.
class PublicBodyProcessor < Pupa::Processor
  # This transformation task will write a CSV row for each scraped organization.
  # You can name transformation tasks whatever you like.
  def csv
    puts CSV.generate_line %w(
      title
      abbr
      key
      category
      parent
      parent_key
      description
      url
      jurisdiction
      jurisdiction_code
      source
      source_url
      address
      contact
      email
      tags
    )

    # `organizations` is a lazy enumerator of all scraped organizations, so
    # we'll see a CSV row printed as soon as an organization is scraped.
    organizations.each do |organization|
      puts CSV.generate_line [
        organization.name,
        nil,
        organization._id,
        organization.classification,
        nil,
        nil,
        nil,
        'New Brunswick',
        'ocd-division/country:ca/province:nb',
        organization.sources[0][:note],
        organization.sources[0][:url],
        organization.contact_details.address,
        organization.extras[:contact_point],
        organization.contact_details.email,
        nil,
        nil,
        nil,
      ]
    end
  end

  # To keep this example short, we'll just scrape the departments and agencies
  # of the Government of New Brunswick.
  def scrape_organizations
    url = 'http://www1.gnb.ca/cnb/DsS/display-e.asp?typyofPublicBodyID=1'
    doc = get(url)

    doc.xpath('//table[4]//table').each do |table|
      organization = Pupa::Organization.new
      organization.name = table.at_xpath('.//u').text
      address = table.text.strip[/\A#{Regexp.escape(organization.name)}(.+?)(?=Co-ordinator:|Email:|Phone:|Fax:)/m, 1].gsub(/[[:space:]]{2,}/, "\n").strip
      email = clean(table.at_xpath('.//a/@href').value).sub(/\Amailto:/, '')
      contact_detail = table.at_xpath('.//u[text()="Co-ordinator"]').next.text.sub(/\A: /, '')
      organization.add_contact_detail('address', address)
      organization.add_extra(:contact_detail, contact_detail)
      organization.add_contact_detail('email', email)
      organization.add_source(url, note: 'New Brunswick Directory of Public Bodies')
      dispatch(organization)
    end
  end
end

PublicBodyProcessor.add_scraping_task(:organizations)

runner = Pupa::Runner.new(PublicBodyProcessor)
# Registers the `csv` action, so that we can run it with:
#
#     ruby organization.rb --action csv > output.csv
runner.add_action(name: 'csv', description: 'Output organizations as CSV')
runner.run(ARGV)

# You've won at Pupa.rb! Explore the [class and method documentation](http://rdoc.info/gems/pupa)
# to learn how to do even more with Pupa.rb.
