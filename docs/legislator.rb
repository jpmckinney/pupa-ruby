require 'pupa'

# The [cat.rb](http://opennorth.github.io/pupa-ruby/docs/cat.html) example goes
# over the basics of using Pupa.rb, and [bill.rb](http://opennorth.github.io/pupa-ruby/docs/bill.html)
# covers some more advanced topics. This will explain how to run, for example,
# different methods to scrape legislators depending on the legislative term -
# particularly useful if a data source changes format from year to year.

# parl.gc.ca uses ASP.NET forms, so we need [bigger guns](http://mechanize.rubyforge.org/).
require 'mechanize'

class LegislatorProcessor < Pupa::Processor
  # The data source publishes information from different parliaments in
  # different formats. We override `extract_task_method` to select the method
  # used to extract legislators according to the parliament.
  def extract_task_method(task_name)
    if task_name == :people
      # If the task is to extract people and a parliament is given, we select a
      # method according to the parliament.
      if @options.key?('parliament')
        if @options['parliament'].to_i >= 36
          "extract_people_36th_to_date"
        else
          "extract_people_1st_to_35th"
        end
      # If no parliament is given, we assume the parliament is recent, as it is
      # much more common to scrape current data than historical data.
      else
        "extract_people_36th_to_date"
      end
    # Otherwise, it uses the default behavior for other extraction tasks.
    else
      super
    end
  end

  # A little helper method to put name components in a typical order.
  def swap_first_last_name(name)
    name.strip.match(/\A([^,]+?), ([^(]+?)(?: \(.+\))?\z/)[1..2].
      reverse.map{|component| component.strip.squeeze(' ')}.join(' ')
  end

  def extract_people_36th_to_date
    url = 'http://www.parl.gc.ca/MembersOfParliament/MainMPsCompleteList.aspx?TimePeriod=Historical&Language=E'
    doc = if @options.key?('parliament')
      # Since we are not using the default Faraday HTTP client, we manually
      # configure the Mechanize HTTP client to use Pupa.rb's logger.
      client = Mechanize.new
      client.log = Pupa::Logger.new('mechanize', level: @level)
      page = client.get(url)
      page.form['MasterPage$MasterPage$BodyContent$PageContent$Content$ListCriteriaContent$ListCriteriaContent$ucComboParliament$cboParliaments'] = @options['parliament']
      page.form.submit.parser
    else
      get(url)
    end

    doc.css('#MasterPage_MasterPage_BodyContent_PageContent_Content_ListContent_ListContent_grdCompleteList tr:gt(1)').each do |row|
      person = Pupa::Person.new
      person.name = swap_first_last_name(row.at_css('td:eq(1)').text)
      Fiber.yield(person)
    end
  end

  def extract_people_1st_to_35th
    list_url = 'http://www.parl.gc.ca/Parlinfo/Lists/Members.aspx?Language=E'
    page_url = 'http://www.parl.gc.ca/Parlinfo/Lists/Members.aspx?Language=E&Parliament=%s&Riding=&Name=&Party=&Province=&Gender=&New=False&Current=False&First=False&Picture=False&Section=False&ElectionDate='
    doc = get(list_url)
    value = doc.at_xpath("//select[@id='ctl00_cphContent_cboParliamentCriteria']/option[starts-with(.,'#{@options['parliament']}')]/@value").value
    doc = get(page_url % value)

    doc.css('tr:gt(1)').each do |row|
      person = Pupa::Person.new
      person.name = swap_first_last_name(row.at_css('td:eq(1)').text)
      Fiber.yield(person)
    end
  end
end

LegislatorProcessor.add_extract_task(:people)

# To add extraction method selection criteria, call `legislator.rb` as:
#
#     ruby legislator.rb [options] -- [criteria]
#
# So, for example, to extract and load legislators from the 37th parliament:
#
#     ruby legislator.rb -- parliament 37
#
# Or, to extract but not load legislators from the 12th parliament:
#
#     ruby legislator.rb --action extract -- parliament 12
Pupa::Runner.new(LegislatorProcessor).run(ARGV)
