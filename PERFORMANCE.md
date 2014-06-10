# Pupa.rb: A Data Scraping Framework

## Performance

Pupa.rb offers several ways to significantly improve performance.

In an example case, reducing disk I/O and skipping validation as described below reduced the time to scrape 10,000 documents from 100 cached HTTP responses from 100 seconds down to 5 seconds. Like fast tests, fast scrapers make development smoother.

The `import` action's performance is currently limited by the database when a dependency graph is used to determine the evaluation order. If a dependency graph cannot be used because you don't know a related object's ID, [several optimizations](https://github.com/opennorth/pupa-ruby/issues/12) can be implemented to improve performance.

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

The [pupa-validate](https://npmjs.org/package/pupa-validate) npm package can be used to validate JSON documents using the faster JSV. In an example case, using JSV instead of the `json-schema` gem reduced by half the time to validate 10,000 documents.

### Ruby version

Pupa.rb requires Ruby 2.x. If you have already made all the above optimizations, you may notice a significant improvement by using Ruby 2.1, which has better garbage collection than Ruby 2.0.

### Profiling

You can profile your code using [perftools.rb](https://github.com/tmm1/perftools.rb). First, install the gem:

    gem install perftools.rb

Then, run your script with the profiler (changing `/tmp/PROFILE_NAME` and `script.rb` as appropriate):

    CPUPROFILE=/tmp/PROFILE_NAME RUBYOPT="-r`gem which perftools | tail -1`" ruby script.rb

You may want to set the `CPUPROFILE_REALTIME=1` flag; however, it seems to interfere with HTTP requests, for whatever reason.

[perftools.rb](https://github.com/tmm1/perftools.rb) has several output formats. If your code is straight-forward, you can draw a graph (changing `/tmp/PROFILE_NAME` and `/tmp/PROFILE_NAME.pdf` as appropriate):

    pprof.rb --pdf /tmp/PROFILE_NAME > /tmp/PROFILE_NAME.pdf
