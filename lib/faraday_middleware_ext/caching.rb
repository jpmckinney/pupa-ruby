module FaradayMiddewareExt
  refine FaradayMiddleware::Caching do
    def call(env)
      # Remove if-statement to cache any request, not only GET.
      if env[:parallel_manager]
        # callback mode
        cache_on_complete(env)
      else
        # synchronous mode
        response = cache.fetch(cache_key(env)) { @app.call(env) }
        finalize_response(response, env)
      end
    end

    def cache_key(env)
      url = env[:url].dup
      if url.query && params_to_ignore.any?
        params = parse_query url.query
        params.reject! {|k,| params_to_ignore.include? k }
        url.query = build_query params
      end
      url.normalize!
      url.request_uri + env[:body].to_s # Add for POST requests.
    end
  end
end
