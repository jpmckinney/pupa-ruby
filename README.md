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

## Performance

Pupa.rb offers several ways to significantly improve performance.

### Caching HTTP requests

HTTP requests consume the most time. To avoid repeat HTTP requests while developing a scraper, cache all HTTP responses. Pupa.rb will by default use a `web_cache` directory in the same directory as your script. You can change the directory by setting the `--cache_dir` switch on the command line, for example:

    ruby cat.rb --cache_dir my_cache_dir

### Reducing file I/O

After HTTP requests, file I/O is the slowest operation. Two types of files are written to disk: HTTP responses are written to the cache directory, and JSON documents are written to the output directory. Writing to memory is much faster than writing to disk. You may store HTTP responses in [Memcached](http://memcached.org/) like so:

    ruby cat.rb --cache_dir memcached://localhost:11211

And you may store JSON documents in [Redis](http://redis.io/) like so:

    ruby cat.rb --output_dir redis://localhost:6379/0

Note that Pupa.rb flushes the JSON documents before scraping. If you use Redis, **DO NOT** share a Redis database with Pupa.rb and other applications. You can select a different database than the default `0` for use with Pupa.rb by passing an argument like `redis://localhost:6379/1`, where `1` is the Redis database number.

### Other improvements

The `json-schema` gem is slow compared to, for example, [JSV](https://github.com/garycourt/JSV). Setting the `--no-validate` switch and running JSON Schema validations separately can further reduce a scraper's running time.

### Profiling

You can profile your code using [perftools.rb](https://github.com/tmm1/perftools.rb). First, install the gem:

    gem install perftools.rb

Then, run your `script.rb` with the profiler, storing the results to `/tmp/PROFILE_NAME` in this example:

    CPUPROFILE=/tmp/PROFILE_NAME RUBYOPT="-r`gem which perftools | tail -1`" ruby script.rb

You may want to set the `CPUPROFILE_REALTIME=1` flag; however, for whatever reason, it seems to change the behavior of the `json-schema` gem.

[perftools.rb](https://github.com/tmm1/perftools.rb) has several output formats. If your code is straight-forward, you can draw a graph to `/tmp/PROFILE_NAME.pdf` with:

    pprof.rb --pdf /tmp/PROFILE_NAME > /tmp/PROFILE_NAME.pdf

## Testing

**DO NOT** run this gem's specs if you are using Redis database number 15 on `localhost`!

## Bugs? Questions?

This project's main repository is on GitHub: [http://github.com/opennorth/pupa-ruby](http://github.com/opennorth/pupa-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
