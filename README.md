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

### Automatic response parsing

JSON parsing is enabled by default. To enable automatic parsing of HTML and XML, require the `nokogiri` and `multi_xml` gems.

## Performance

Pupa.rb offers several ways to significantly improve performance.

In an example case, reducing disk I/O and skipping validation as described below reduced the time to scrape 10,000 documents from 100 cached HTTP responses from 100 seconds down to 5 seconds. Like fast tests, fast scrapers make development smoother.

The `import` action's performance is currently limited by MongoDB when a dependency graph is used to determine the evaluation order. If a dependency graph cannot be used because you don't know a related object's ID, [several optimizations](https://github.com/opennorth/pupa-ruby/issues/12) can be implemented to improve performance.

### Reducing HTTP requests

HTTP requests consume the most time. To avoid repeat HTTP requests while developing a scraper, cache all HTTP responses. Pupa.rb will by default use a `web_cache` directory in the same directory as your script. You can change the directory by setting the `--cache_dir` switch on the command line, for example:

    ruby cat.rb --cache_dir /tmp/my_cache_dir

### Parallelizing HTTP requests

To enable parallel requests, use the `typhoeus` gem. Unless you are using an old version of Typhoeus (< 0.5), both Faraday and Typhoeus define a Faraday adapter, but you must use the one defined by Typhoeus, like so:

```ruby
require 'pupa'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
```

Then, in your scraping methods, write code like:

```ruby
responses = []

# Change the maximum number of concurrent requests (default 200). You usually
# need to tweak this number by trial and error.
# @see https://github.com/lostisland/faraday/wiki/Parallel-requests#advanced-use
manager = Typhoeus::Hydra.new(max_concurrency: 20)

begin
  # Send HTTP requests in parallel.
  client.in_parallel(manager) do
    responses << client.get('http://example.com/foo')
    responses << client.get('http://example.com/bar')
    # More requests...
  end
rescue Faraday::Error::ClientError => e
  # Log an error message if, for example, you exceed a server's maximum number
  # of concurrent connections or if you exceed an API's rate limit.
  error(e.response.inspect)
end

# Responses are now available for use.
responses.each do |response|
  # Only process the finished responses.
  if response.success?
    # If success...
  elsif response.finished?
    # If error...
  end
end
```

### Reducing disk I/O

After HTTP requests, disk I/O is the slowest operation. Two types of files are written to disk: HTTP responses are written to the cache directory, and JSON documents are written to the output directory. Writing to memory is much faster than writing to disk.

#### RAM file systems

A simple solution is to create a file system in RAM, like `tmpfs` on Linux for example, and to use it as your `output_dir` and  `cache_dir`. On OS X, you must create a RAM disk. To create a 128MB RAM disk, for example, run:

    ramdisk=$(hdiutil attach -nomount ram://$((128 * 2048)) | tr -d ' \t')
    diskutil erasevolume HFS+ 'ramdisk' $ramdisk

You can then set the `output_dir` and `cache_dir` on OS X as:

    ruby cat.rb --output_dir /Volumes/ramdisk/scraped_data --cache_dir /Volumes/ramdisk/web_cache

Once you are done with the RAM disk, release the memory:

    diskutil unmount $ramdisk
    hdiutil detach $ramdisk

Using a RAM disk will significantly improve performance; however, the data will be lost between reboots unless you move the data to a hard disk. Using Memcached (for caching) and Redis (for storage) is moderately faster than using a RAM disk, and Redis will not lose your output data between reboots.

#### Memcached

You may cache HTTP responses in [Memcached](http://memcached.org/). First, require the `dalli` gem. Then:

    ruby cat.rb --cache_dir memcached://localhost:11211

The data in Memcached will be lost between reboots.

#### Redis

You may dump JSON documents in [Redis](http://redis.io/). First, require the `redis-store` gem. Then:

    ruby cat.rb --output_dir redis://localhost:6379/0

To dump JSON documents in Redis moderately faster, use [pipelining](http://redis.io/topics/pipelining):

    ruby cat.rb --output_dir redis://localhost:6379/0 --pipelined

Requiring the `hiredis` gem will slightly improve performance.

Note that Pupa.rb flushes the Redis database before scraping. If you use Redis, **DO NOT** share a Redis database with Pupa.rb and other applications. You can select a different database than the default `0` for use with Pupa.rb by passing an argument like `redis://localhost:6379/15`, where `15` is the database number.

### Skipping validation

The `json-schema` gem is slow compared to, for example, [JSV](https://github.com/garycourt/JSV). Setting the `--no-validate` switch and running JSON Schema validations separately can further reduce a scraper's running time.

### Parsing JSON

If the rest of your scraper is fast, you may see an improvement by using the `oj` gem. Just `require 'oj'` and Pupa.rb will automatically pick it up, since it uses [MultiJson](https://github.com/intridea/multi_json).

### Profiling

You can profile your code using [perftools.rb](https://github.com/tmm1/perftools.rb). First, install the gem:

    gem install perftools.rb

Then, run your script with the profiler (changing `/tmp/PROFILE_NAME` and `script.rb` as appropriate):

    CPUPROFILE=/tmp/PROFILE_NAME RUBYOPT="-r`gem which perftools | tail -1`" ruby script.rb

You may want to set the `CPUPROFILE_REALTIME=1` flag; however, it seems to interfere with HTTP requests, for whatever reason.

[perftools.rb](https://github.com/tmm1/perftools.rb) has several output formats. If your code is straight-forward, you can draw a graph (changing `/tmp/PROFILE_NAME` and `/tmp/PROFILE_NAME.pdf` as appropriate):

    pprof.rb --pdf /tmp/PROFILE_NAME > /tmp/PROFILE_NAME.pdf

## Testing

**DO NOT** run this gem's specs if you are using Redis database number 15 on `localhost`!

## Bugs? Questions?

This project's main repository is on GitHub: [http://github.com/opennorth/pupa-ruby](http://github.com/opennorth/pupa-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
