# Pupa-Ruby: A Data Scraping Framework

[![Build Status](https://secure.travis-ci.org/opennorth/pupa-ruby.png)](http://travis-ci.org/opennorth/pupa-ruby)
[![Dependency Status](https://gemnasium.com/opennorth/pupa-ruby.png)](https://gemnasium.com/opennorth/pupa-ruby)
[![Coverage Status](https://coveralls.io/repos/opennorth/pupa-ruby/badge.png?branch=master)](https://coveralls.io/r/opennorth/pupa-ruby)
[![Code Climate](https://codeclimate.com/github/opennorth/pupa-ruby.png)](https://codeclimate.com/github/opennorth/pupa-ruby)

Pupa-Ruby is a Ruby version of Sunlight Labs' [Pupa](https://github.com/opencivicdata/pupa).

It uses the [Popolo](http://popoloproject.com/) data specification for open government data.

## Usage

```ruby
require 'pupa'

class MyScraper < Pupa::Scraper
  tech = Organization.new('Committee on Technology', classification: 'committee')
  tech.add_source('https://example.com')
  Fiber.yield tech

  ecom = Organization.new('Subcommittee on E-Commerce', classification: 'committee', parent: tech)
  ecom.add_source('https://example.com')
  Fiber.yield ecom

  p = Person('Paul Tagliamonte')
  p.add_source('https://example.com')
  Fiber.yield p
end
```

## Bugs? Questions?

This project's main repository is on GitHub: [http://github.com/opennorth/pupa-ruby](http://github.com/opennorth/pupa-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
