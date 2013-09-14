# Pupa.rb: A Data Scraping Framework

[![Build Status](https://secure.travis-ci.org/opennorth/pupa-ruby.png)](http://travis-ci.org/opennorth/pupa-ruby)
[![Dependency Status](https://gemnasium.com/opennorth/pupa-ruby.png)](https://gemnasium.com/opennorth/pupa-ruby)
[![Coverage Status](https://coveralls.io/repos/opennorth/pupa-ruby/badge.png?branch=master)](https://coveralls.io/r/opennorth/pupa-ruby)
[![Code Climate](https://codeclimate.com/github/opennorth/pupa-ruby.png)](https://codeclimate.com/github/opennorth/pupa-ruby)

Pupa.rb is a Ruby 2.0 fork of Sunlight Labs' [Pupa](https://github.com/opencivicdata/pupa). It implements an Extract, Transform and Load (ETL) process to scrape data from online sources, transform it, and write it to a database.

## Usage

You can use Pupa.rb to author scrapers that create people, organizations, memberships and posts according to the [Popolo](http://popoloproject.com/) open government data specification. If you need to scrape other types of data, you can also use your own models with Pupa.rb.

The [cat.rb](http://opennorth.github.io/pupa-ruby/docs/cat.html) example shows you how to:

* write a simple Cat class that is compatible with Pupa.rb
* use mixins to add Popolo properties to your class
* write a processor to scrape Cat objects from the Internet
* register a scraping task with Pupa.rb
* run the processor to save the Cat objects to MongoDB

The [bill.rb](http://opennorth.github.io/pupa-ruby/docs/bill.html) example shows you how to:

* create relations between objects
* relate two objects, even if you do not know the ID of one object
* write separate scraping tasks for different types of data
* run each scraping task separately

The [legislator.rb](http://opennorth.github.io/pupa-ruby/docs/legislator.html) example shows you how to:

* use a different HTTP client than the default [Faraday](https://github.com/lostisland/faraday)
* select a scraping method according to criteria like the legislative term
* pass selection criteria to the processor before running scraping tasks

The [organization.rb](http://opennorth.github.io/pupa-ruby/docs/organization.html) example shows you how to:

* register a transformation task with Pupa.rb
* run the processor's transformation task

### Scraping method selection

1.  For simple processing, your processor class need only define a single `scrape_objects` method, which will perform all scraping. See [cat.rb](http://opennorth.github.io/pupa-ruby/docs/cat.html) for an example.

1.  If you scrape many types of data from the same source, you may want to split the scraping into separate tasks according to the type of data being scraped. See [bill.rb](http://opennorth.github.io/pupa-ruby/docs/bill.html) for an example.

1.  You may want more control over the method used to perform a scraping task. For example, a legislature may publish legislators before 1997 in one format and legislators after 1997 in another format. In this case, you may want to select the method used to scrape legislators according to the year. See [legislator.rb](http://opennorth.github.io/pupa-ruby/docs/legislator.html).

## Bugs? Questions?

This project's main repository is on GitHub: [http://github.com/opennorth/pupa-ruby](http://github.com/opennorth/pupa-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
