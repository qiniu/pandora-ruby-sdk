module Pandora
  module Transport
    module Transport

      # @abstract Module with common functionality for transport implementations.
      #
      module Base
        DEFAULT_PORT             = 9188 
        DEFAULT_PROTOCOL         = 'http'
        DEFAULT_RESURRECT_AFTER  = 60     # Seconds
        DEFAULT_MAX_RETRIES      = 3      # Requests
        DEFAULT_SERIALIZER_CLASS = Serializer::MultiJson
        SANITIZED_PASSWORD       = '*' * (rand(14)+1)
        HTTP_TIME_FORMAT = "%a, %d %b %Y %H:%M:%S GMT"

        attr_reader   :hosts, :options, :connections, :counter, :last_request_at, :protocol
        attr_accessor :serializer, :logger, :tracer,
                      :resurrect_after, :max_retries

        # Creates a new transport object
        #
        # @param arguments [Hash] Settings and options for the transport
        # @param block     [Proc] Lambda or Proc which can be evaluated in the context of the "session" object
        #
        # @option arguments [Array] :hosts   An Array of normalized hosts information
        # @option arguments [Array] :options A Hash with options (usually passed by {Client})
        #
        # @see Client#initialize
        #
        def initialize(arguments={}, &block)
          @state_mutex = Mutex.new

          @hosts       = arguments[:hosts]   || []
          @options     = arguments[:options] || {}
          @options[:http] ||= {}
          @options[:retry_on_status] ||= []

          @block       = block
          @connections = __build_connections

          @serializer  = options[:serializer] || ( options[:serializer_class] ? options[:serializer_class].new(self) : DEFAULT_SERIALIZER_CLASS.new(self) )
          @protocol    = options[:protocol] || DEFAULT_PROTOCOL

          @logger      = options[:logger]
          @tracer      = options[:tracer]

          @counter     = 0
          @counter_mtx = Mutex.new
          @last_request_at = Time.now
          @resurrect_after = options[:resurrect_after] || DEFAULT_RESURRECT_AFTER
          @max_retries     = options[:retry_on_failure].is_a?(Integer)   ? options[:retry_on_failure]   : DEFAULT_MAX_RETRIES
          @retry_on_status = Array(options[:retry_on_status]).map { |d| d.to_i }

          @ak = @options[:ak]
          @sk = @options[:sk]
          @qiniu_header_prefix="X-Qiniu-"
          @qiniu_sub_resource=Array.new
        end

        # Returns a connection from the connection pool by delegating to {Connections::Collection#get_connection}.
        #
        # Resurrects dead connection if the `resurrect_after` timeout has passed.
        #
        # @return [Connections::Connection]
        # @see    Connections::Collection#get_connection
        #
        def get_connection(options={})
          resurrect_dead_connections! if Time.now > @last_request_at + @resurrect_after

          @counter_mtx.synchronize { @counter += 1 }
          connections.get_connection(options)
        end

        # Tries to "resurrect" all eligible dead connections
        #
        # @see Connections::Connection#resurrect!
        #
        def resurrect_dead_connections!
          connections.dead.each { |c| c.resurrect! }
        end

        # Rebuilds the connections collection in the transport.
        #
        # The methods *adds* new connections from the passed hosts to the collection,
        # and *removes* all connections not contained in the passed hosts.
        #
        # @return [Connections::Collection]
        # @api private
        #
        def __rebuild_connections(arguments={})
          @state_mutex.synchronize do
            @hosts       = arguments[:hosts]    || []
            @options     = arguments[:options]  || {}

            __close_connections

            new_connections = __build_connections
            stale_connections = @connections.all.select  { |c| ! new_connections.include?(c) }
            new_connections = new_connections.reject { |c| @connections.include?(c) }

            @connections.remove(stale_connections)
            @connections.add(new_connections)
            @connections
          end
        end

        # Builds and returns a collection of connections
        #
        # The adapters have to implement the {Base#__build_connection} method.
        #
        # @return [Connections::Collection]
        # @api    private
        #
        def __build_connections
          Connections::Collection.new \
            :connections => hosts.map { |host|
              host[:protocol] = host[:scheme] || options[:scheme] || options[:http][:scheme] || DEFAULT_PROTOCOL
              host[:port] ||= options[:port] || options[:http][:scheme] || DEFAULT_PORT
              if (options[:user] || options[:http][:user]) && !host[:user]
                host[:user] ||= options[:user] || options[:http][:user]
                host[:password] ||= options[:password] || options[:http][:password]
              end

              __build_connection(host, (options[:transport_options] || {}), @block)
            },
            :selector_class => options[:selector_class],
            :selector => options[:selector]
        end

        # @abstract Build and return a connection.
        #           A transport implementation *must* implement this method.
        #           See {HTTP::Faraday#__build_connection} for an example.
        #
        # @return [Connections::Connection]
        # @api    private
        #
        def __build_connection(host, options={}, block=nil)
          raise NoMethodError, "Implement this method in your class"
        end

        # Closes the connections collection
        #
        # @api private
        #
        def __close_connections
          # A hook point for specific adapters when they need to close connections
        end

        # Log request and response information
        #
        # @api private
        #
        def __log(method, path, params, body, url, response, json, took, duration)
          sanitized_url = url.to_s.gsub(/\/\/(.+):(.+)@/, '//' + '\1:' + SANITIZED_PASSWORD +  '@')
          logger.info  "#{method.to_s.upcase} #{sanitized_url} " +
                       "[status:#{response.status}, request:#{sprintf('%.3fs', duration)}, query:#{took}]"
          logger.debug "> #{__convert_to_json(body)}" if body
          logger.debug "< #{response.body}"
        end

        # Log failed request
        #
        # @api private
        #
        def __log_failed(response)
          logger.fatal "[#{response.status}] #{response.body}"
        end

        # Trace the request in the `curl` format
        #
        # @api private
        #
        def __trace(method, path, params, body, url, response, json, took, duration)
          trace_url  = "http://localhost:9188/#{path}" +
                       ( params.empty? ? '' : "?#{::Faraday::Utils::ParamsHash[params].to_query}" )
          trace_body = body ? " -d '#{__convert_to_json(body, :pretty => true)}'" : ''
          tracer.info  "curl -X #{method.to_s.upcase} '#{trace_url}'#{trace_body}\n"
          tracer.debug "# #{Time.now.iso8601} [#{response.status}] (#{format('%.3f', duration)}s)\n#"
          tracer.debug json ? serializer.dump(json, :pretty => true).gsub(/^/, '# ').sub(/\}$/, "\n# }")+"\n" : "# #{response.body}\n"
        end

        # Raise error specific for the HTTP response status or a generic server error
        #
        # @api private
        #
        def __raise_transport_error(response)
          error = ERRORS[response.status] || ServerError
          raise error.new "[#{response.status}] #{response.body}"
        end

        # Converts any non-String object to JSON
        #
        # @api private
        #
        def __convert_to_json(o=nil, options={})
          o = o.is_a?(String) ? o : serializer.dump(o, options)
        end

        # Returns a full URL based on information from host
        #
        # @param host [Hash] Host configuration passed in from {Client}
        #
        # @api private
        def __full_url(host)
          url  = "#{host[:protocol]}://"
          url += "#{CGI.escape(host[:user])}:#{CGI.escape(host[:password])}@" if host[:user]
          url += "#{host[:host]}:#{host[:port]}"
          url += "#{host[:path]}" if host[:path]
          url
        end

        def sign_qiniu_header(headers)
          keys = Array.new
          headers.each do |key, value| 
        	if key.length > @qiniu_header_prefix.length && key[0,@qiniu_header_prefix.length] == @qiniu_header_prefix
        	  keys << key
        	end
          end
        
          if keys.length == 0
            return ""
          end
        
          keys.sort! { |x,y| x <=> y }
          keys.inject("") { |out, key| "#{out}\n#{key}:#{headers[key]}" }
        end
        
        def sign_qiniu_resource(path, params)
          keys = Array.new
          @qiniu_sub_resource.each do |key|
            if !params[key].nil?
              keys << params[key] 
            end
          end 
        
          keys.inject("#{path}?") { |out, key| "#{out}#{key}=#{params[key]}&" }.chop
        end
        
        def sign_request(method, path, params, headers)
          headers['Date'] = Time.now.gmtime.strftime(HTTP_TIME_FORMAT)
        
          digest = ::OpenSSL::Digest.new('sha1')
          hmac = ::Base64.urlsafe_encode64(OpenSSL::HMAC.digest(digest, @sk, "#{method}\n#{headers['Content-MD5']}\n#{headers['Content-Type']}\n#{headers['Date']}\n#{sign_qiniu_header headers}#{sign_qiniu_resource path, params}"))
        
          headers['Authorization'] = begin
        	"Pandora #{@ak}:#{hmac}"
          end
        end

        # Performs a request to Pandora, while handling logging, tracing, marking dead connections,
        # retrying the request and reloading the connections.
        #
        # @abstract The transport implementation has to implement this method either in full,
        #           or by invoking this method with a block. See {HTTP::Faraday#perform_request} for an example.
        #
        # @param method [String] Request method
        # @param path   [String] The API endpoint
        # @param params [Hash]   Request parameters (will be serialized by {Connections::Connection#full_url})
        # @param body   [Hash]   Request body (will be serialized by the {#serializer})
        # @param block  [Proc]   Code block to evaluate, passed from the implementation
        #
        # @return [Response]
        # @raise  [NoMethodError] If no block is passed
        # @raise  [ServerError]   If request failed on server
        # @raise  [Error]         If no connection is available
        #
        def perform_request(method, path, params={}, body=nil, &block)
          raise NoMethodError, "Implement this method in your transport class" unless block_given?
          start = Time.now if logger || tracer
          tries = 0

          params = params.clone

          ignore = Array(params.delete(:ignore)).compact.map { |s| s.to_i }

          begin
            tries     += 1
            connection = get_connection or raise Error.new("Cannot get new connection from pool.")

            if connection.connection.respond_to?(:params) && connection.connection.params.respond_to?(:to_hash)
              params = connection.connection.params.merge(params.to_hash)
            end

            url        = connection.full_url(path, params)

			sign_request method, path, params, connection.connection.headers if @ak && @sk 
			connection.connection.headers.delete 'X-Appid' if @ak && @sk 

            response   = block.call(connection, url)

            connection.healthy! if connection.failures > 0

            # Raise an exception so we can catch it for `retry_on_status`
            __raise_transport_error(response) if response.status.to_i >= 300 && @retry_on_status.include?(response.status.to_i)

          rescue Pandora::Transport::Transport::ServerError => e
            if @retry_on_status.include?(response.status)
              logger.warn "[#{e.class}] Attempt #{tries} to get response from #{url}" if logger
              if tries <= max_retries
                retry
              else
                logger.fatal "[#{e.class}] Cannot get response from #{url} after #{tries} tries" if logger
                raise e
              end
            else
              raise e
            end

          rescue *host_unreachable_exceptions => e
            logger.error "[#{e.class}] #{e.message} #{connection.host.inspect}" if logger

            connection.dead!

            if @options[:retry_on_failure]
              logger.warn "[#{e.class}] Attempt #{tries} connecting to #{connection.host.inspect}" if logger
              if tries <= max_retries
                retry
              else
                logger.fatal "[#{e.class}] Cannot connect to #{connection.host.inspect} after #{tries} tries" if logger
                raise e
              end
            else
              raise e
            end

          rescue Exception => e
            logger.fatal "[#{e.class}] #{e.message} (#{connection.host.inspect if connection})" if logger
            raise e

          end #/begin

          duration = Time.now-start if logger || tracer

          if response.status.to_i >= 300
            __log    method, path, params, body, url, response, nil, 'N/A', duration if logger
            __trace  method, path, params, body, url, response, nil, 'N/A', duration if tracer

            # Log the failure only when `ignore` doesn't match the response status
            __log_failed response if logger && !ignore.include?(response.status.to_i)

            __raise_transport_error response unless ignore.include?(response.status.to_i)
          end

          json     = serializer.load(response.body) if response.body && !response.body.empty? && response.headers && response.headers["content-type"] =~ /json/
          took     = (json['took'] ? sprintf('%.3fs', json['took']/1000.0) : 'n/a') rescue 'n/a' if logger || tracer

          __log   method, path, params, body, url, response, json, took, duration if logger && !ignore.include?(response.status.to_i)
          __trace method, path, params, body, url, response, json, took, duration if tracer

          Response.new response.status, json || response.body, response.headers
        ensure
          @last_request_at = Time.now
        end

        # @abstract Returns an Array of connection errors specific to the transport implementation.
        #           See {HTTP::Faraday#host_unreachable_exceptions} for an example.
        #
        # @return [Array]
        #
        def host_unreachable_exceptions
          [Errno::ECONNREFUSED]
        end
      end
    end
  end
end
