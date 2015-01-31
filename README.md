# Pupa.rb: A Data Scraping Framework

[![Gem Version](https://badge.fury.io/rb/pupa.svg)](https://badge.fury.io/rb/pupa)
[![Build Status](https://secure.travis-ci.org/jpmckinney/pupa-ruby.png)](https://travis-ci.org/jpmckinney/pupa-ruby)
[![Dependency Status](https://gemnasium.com/jpmckinney/pupa-ruby.png)](https://gemnasium.com/jpmckinney/pupa-ruby)
[![Coverage Status](https://coveralls.io/repos/jpmckinney/pupa-ruby/badge.png?branch=master)](https://coveralls.io/r/jpmckinney/pupa-ruby)
[![Code Climate](https://codeclimate.com/github/jpmckinney/pupa-ruby.png)](https://codeclimate.com/github/jpmckinney/pupa-ruby)

Pupa.rb is a Ruby 2.x fork of Python [Pupa](https://github.com/opencivicdata/pupa). It implements an Extract, Transform and Load (ETL) process to scrape data from online sources, transform it, and write it to a database.

    gem install pupa

## Usage

You can scrape any sort of data with Pupa.rb using your own models. You can also use Pupa.rb to scrape people, organizations, memberships and posts according to the [Popolo](http://www.popoloproject.com/) open government data specification. This gem is up-to-date with Popolo's 2014-10-28 version.

The [cat.rb](http://jpmckinney.github.io/pupa-ruby/docs/cat.html) example shows you how to:

* write a simple Cat class that is compatible with Pupa.rb
* use mixins to add Popolo properties to your class
* write a processor to scrape Cat objects from the Internet
* register a scraping task with Pupa.rb
* run the processor to save the Cat objects to MongoDB

The [bill.rb](http://jpmckinney.github.io/pupa-ruby/docs/bill.html) example shows you how to:

* create relations between objects
* relate two objects, even if you do not know the ID of one object
* write separate scraping tasks for different types of data
* run each scraping task separately

The [legislator.rb](http://jpmckinney.github.io/pupa-ruby/docs/legislator.html) example shows you how to:

* use a different HTTP client than the default [Faraday](https://github.com/lostisland/faraday)
* select a scraping method according to criteria like the legislative term
* pass selection criteria to the processor before running scraping tasks

The [organization.rb](http://jpmckinney.github.io/pupa-ruby/docs/organization.html) example shows you how to:

* register a transformation task with Pupa.rb
* run the processor's transformation task

### Scraping method selection

1.  For simple processing, your processor class need only define a single `scrape_objects` method, which will perform all scraping. See [cat.rb](http://jpmckinney.github.io/pupa-ruby/docs/cat.html) for an example.

1.  If you scrape many types of data from the same source, you may want to split the scraping into separate tasks according to the type of data being scraped. See [bill.rb](http://jpmckinney.github.io/pupa-ruby/docs/bill.html) for an example.

1.  You may want more control over the method used to perform a scraping task. For example, a legislature may publish legislators before 1997 in one format and legislators after 1997 in another format. In this case, you may want to select the method used to scrape legislators according to the year. See [legislator.rb](http://jpmckinney.github.io/pupa-ruby/docs/legislator.html).

### Automatic response parsing

JSON parsing is enabled by default. To enable automatic parsing of HTML and XML, require the `nokogiri` and `multi_xml` gems.

## Performance

Pupa.rb offers several ways to significantly improve performance. [Read the documentation.](https://github.com/jpmckinney/pupa-ruby/blob/master/PERFORMANCE.md#readme)

## Integration with ODMs

`Pupa::Model` is incompatible with `Mongoid::Document`. **Don't do this**:

```ruby
class Cat
  include Pupa::Model
  include Mongoid::Document
end
```

Instead, have a simple scraping model that includes `Pupa::Model` and an app model that includes `Mongoid::Document` with your app's business logic.

## What it tries to solve

Pupa.rb's goal is to make scraping less painful by solving common problems:

* If you are updating a database by scraping a website, you can either delete and recreate records, or you can merge the scraped records with the saved records. Pupa.rb offers a simple way to merge records, by [using an object's stable properties for identification](http://jpmckinney.github.io/pupa-ruby/docs/cat.html#section-7).
* If you are scraping a source that references other sources – for example, a committee that references its members – you may want to link the source to its references with foreign keys. Pupa.rb will use whatever identifying information you scrape – for example, the members' names – to [fill in the foreign keys for you](http://jpmckinney.github.io/pupa-ruby/docs/bill.html#section-4).
* Data sources may use different formats in different contexts. Pupa.rb makes it easy to [select scraping methods](#scraping-method-selection) according to criteria, like the year of publication [for example](http://jpmckinney.github.io/pupa-ruby/docs/legislator.html#section-3).
* By splitting the scrape (extract) and import (load) steps, it's easier for you and volunteers to start a scraper without any interaction with a database.

In short, Pupa.rb lets you spend more time on the tasks that are unique to your use case, and less time on common tasks like caching, merging and storing data. It also provides helpful features like:

* Logging, to make debugging and monitoring a scraper easier
* [Automatic response parsing](#automatic-response-parsing) of JSON, XML and HTML
* Automatic response decompression
* [Option parsing](http://jpmckinney.github.io/pupa-ruby/docs/legislator.html#section-9), to control your scraper from the command-line
* [Object validation](http://jpmckinney.github.io/pupa-ruby/docs/cat.html#section-4), using [JSON Schema](http://json-schema.org/)

Pupa.rb is extensible, so that you can add your own models, parsers, helpers, actions, etc. It also offers several ways to [improve your scraper's performance](#performance).

## Python [Pupa](https://github.com/opencivicdata/pupa) differences

Both Pupa.rb and Python [Pupa](https://github.com/opencivicdata/pupa) implement models from the [Popolo](http://www.popoloproject.com/) open government data specifications, but Pupa.rb also lets you use your own classes. Pupa.rb stores data in either MongoDB (default) or PostgreSQL (experimental); Python Pupa stores data in PostgreSQL. The PostgreSQL schema of Pupa.rb and Python Pupa differ.

## Testing

**DO NOT** run this gem's specs if you are using Redis database number 15 on `localhost`!

Copyright (c) 2013 James McKinney, released under the MIT license
