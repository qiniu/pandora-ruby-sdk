require 'test_helper'

class Pandora::Transport::Transport::BaseTest < Test::Unit::TestCase

  class EmptyTransport
    include Pandora::Transport::Transport::Base
  end

  class DummyTransport
    include Pandora::Transport::Transport::Base
    def __build_connection(host, options={}, block=nil)
      Pandora::Transport::Transport::Connections::Connection.new :host => host, :connection => Object.new
    end
  end

  class DummyTransportPerformer < DummyTransport
    def perform_request(method, path, params={}, body=nil, &block); super; end
  end

  class DummySerializer
    def initialize(*); end
  end

  context "Transport::Base" do
    should "raise exception when it doesn't implement __build_connection" do
      assert_raise NoMethodError do
        EmptyTransport.new.__build_connection({ :host => 'foo'}, {})
      end
    end

    should "build connections on initialization" do
      DummyTransport.any_instance.expects(:__build_connections)
      transport = DummyTransport.new
    end

    should "have default serializer" do
      transport = DummyTransport.new
      assert_instance_of Pandora::Transport::Transport::Base::DEFAULT_SERIALIZER_CLASS, transport.serializer
    end

    should "have custom serializer" do
      transport = DummyTransport.new :options => { :serializer_class => DummySerializer }
      assert_instance_of DummySerializer, transport.serializer

      transport = DummyTransport.new :options => { :serializer => DummySerializer.new }
      assert_instance_of DummySerializer, transport.serializer
    end

    context "when combining the URL" do
      setup do
        @transport   = DummyTransport.new
        @basic_parts = { :protocol => 'http', :host => 'myhost', :port => 8080 }
      end

      should "combine basic parts" do
        assert_equal 'http://myhost:8080', @transport.__full_url(@basic_parts)
      end

      should "combine path" do
        assert_equal 'http://myhost:8080/api', @transport.__full_url(@basic_parts.merge :path => '/api')
      end

      should "combine authentication credentials" do
        assert_equal 'http://U:P@myhost:8080', @transport.__full_url(@basic_parts.merge :user => 'U', :password => 'P')
      end

      should "escape the username and password" do
        assert_equal 'http://user%40domain:foo%2Fbar@myhost:8080',
                     @transport.__full_url(@basic_parts.merge :user => 'user@domain', :password => 'foo/bar')
      end
    end
  end

  context "getting a connection" do
    setup do
      @transport = DummyTransportPerformer.new
      @transport.stubs(:connections).returns(stub :get_connection => Object.new)
    end

    should "get a connection" do
      assert_not_nil @transport.get_connection
	end

    should "increment the counter" do
      assert_equal 0, @transport.counter
      3.times { @transport.get_connection }
      assert_equal 3, @transport.counter
    end

  end

  context "performing a request" do
    setup do
      @transport = DummyTransportPerformer.new
    end

    should "raise an error when no block is passed" do
      assert_raise NoMethodError do
        @transport.peform_request 'GET', '/'
      end
    end

    should "get the connection" do
      @transport.expects(:get_connection).returns(stub_everything :failures => 1)
      @transport.perform_request 'GET', '/' do; Pandora::Transport::Transport::Response.new 200, 'OK'; end
    end

    should "raise an error when no connection is available" do
      @transport.expects(:get_connection).returns(nil)
      assert_raise Pandora::Transport::Transport::Error do
        @transport.perform_request 'GET', '/' do; Pandora::Transport::Transport::Response.new 200, 'OK'; end
      end
    end

    should "call the passed block" do
      x = 0
      @transport.expects(:get_connection).returns(stub_everything :failures => 1)

      @transport.perform_request 'GET', '/' do |connection, url|
        x += 1
        Pandora::Transport::Transport::Response.new 200, 'OK'
      end

      assert_equal 1, x
    end

    should "deserialize a response JSON body" do
      @transport.expects(:get_connection).returns(stub_everything :failures => 1)
      @transport.serializer.expects(:load).returns({'foo' => 'bar'})

      response = @transport.perform_request 'GET', '/' do
                   Pandora::Transport::Transport::Response.new 200, '{"foo":"bar"}', {"content-type" => 'application/json'}
                 end

      assert_instance_of Pandora::Transport::Transport::Response, response
      assert_equal 'bar', response.body['foo']
    end

    should "not deserialize a response string body" do
      @transport.expects(:get_connection).returns(stub_everything :failures => 1)
      @transport.serializer.expects(:load).never
      response = @transport.perform_request 'GET', '/' do
                   Pandora::Transport::Transport::Response.new 200, 'FOOBAR', {"content-type" => 'text/plain'}
                 end

      assert_instance_of Pandora::Transport::Transport::Response, response
      assert_equal 'FOOBAR', response.body
    end

    should "not deserialize an empty response body" do
      @transport.expects(:get_connection).returns(stub_everything :failures => 1)
      @transport.serializer.expects(:load).never
      response = @transport.perform_request 'GET', '/' do
                   Pandora::Transport::Transport::Response.new 200, '', {"content-type" => 'application/json'}
                 end

      assert_instance_of Pandora::Transport::Transport::Response, response
      assert_equal '', response.body
    end

    should "serialize non-String objects" do
      @transport.serializer.expects(:dump).times(3)
      @transport.__convert_to_json({:foo => 'bar'})
      @transport.__convert_to_json([1, 2, 3])
      @transport.__convert_to_json(nil)
    end

    should "not serialize a String object" do
      @transport.serializer.expects(:dump).never
      @transport.__convert_to_json('{"foo":"bar"}')
    end

    should "raise an error for HTTP status 404" do
      @transport.expects(:get_connection).returns(stub_everything :failures => 1)
      assert_raise Pandora::Transport::Transport::Errors::NotFound do
        @transport.perform_request 'GET', '/' do
          Pandora::Transport::Transport::Response.new 404, 'NOT FOUND'
        end
      end
    end

    should "raise an error for HTTP status 404 with application/json content type" do
      @transport.expects(:get_connection).returns(stub_everything :failures => 1)
      assert_raise Pandora::Transport::Transport::Errors::NotFound do
        @transport.perform_request 'GET', '/' do
          Pandora::Transport::Transport::Response.new 404, 'NOT FOUND', {"content-type" => 'application/json'}
        end
      end
    end

    should "raise an error on server failure" do
      @transport.expects(:get_connection).returns(stub_everything :failures => 1)
      assert_raise Pandora::Transport::Transport::Errors::InternalServerError do
        @transport.perform_request 'GET', '/' do
          Pandora::Transport::Transport::Response.new 500, 'ERROR'
        end
      end
    end

    should "raise an error on connection failure" do
      @transport.expects(:get_connection).returns(stub_everything :failures => 1)

      # `block.expects(:call).raises(::Errno::ECONNREFUSED)` fails on Ruby 1.8
      block = lambda { |a, b| raise ::Errno::ECONNREFUSED }

      assert_raise ::Errno::ECONNREFUSED do
        @transport.perform_request 'GET', '/', &block
      end
    end

    should "not raise an error when the :ignore argument has been passed" do
      @transport.stubs(:get_connection).returns(stub_everything :failures => 1)

      assert_raise Pandora::Transport::Transport::Errors::BadRequest do
        @transport.perform_request 'GET', '/' do
          Pandora::Transport::Transport::Response.new 400, 'CLIENT ERROR'
        end
      end

      # No `BadRequest` error
      @transport.perform_request 'GET', '/', :ignore => 400 do
        Pandora::Transport::Transport::Response.new 400, 'CLIENT ERROR'
      end
    end

    should "mark the connection as dead on failure" do
      c = stub_everything :failures => 1
      @transport.expects(:get_connection).returns(c)

      block = lambda { |a,b| raise ::Errno::ECONNREFUSED }

      c.expects(:dead!)

      assert_raise( ::Errno::ECONNREFUSED ) { @transport.perform_request 'GET', '/', &block }
    end
  end

  context "performing a request with retry on connection failures" do
    setup do
      @transport = DummyTransportPerformer.new :options => { :retry_on_failure => true }
      @transport.stubs(:connections).returns(stub :get_connection => stub_everything(:failures => 1))
      @block = Proc.new { |c, u| puts "UNREACHABLE" }
    end

    should "retry DEFAULT_MAX_RETRIES when host is unreachable" do
      @block.expects(:call).times(4).
            raises(Errno::ECONNREFUSED).
            then.raises(Errno::ECONNREFUSED).
            then.raises(Errno::ECONNREFUSED).
            then.returns(stub_everything :failures => 1)

      assert_nothing_raised do
        @transport.perform_request('GET', '/', &@block)
        assert_equal 4, @transport.counter
      end
    end

    should "raise an error after max tries" do
      @block.expects(:call).times(4).
            raises(Errno::ECONNREFUSED).
            then.raises(Errno::ECONNREFUSED).
            then.raises(Errno::ECONNREFUSED).
            then.raises(Errno::ECONNREFUSED).
            then.returns(stub_everything :failures => 1)

      assert_raise Errno::ECONNREFUSED do
        @transport.perform_request('GET', '/', &@block)
      end
    end
  end unless RUBY_1_8

  context "performing a request with retry on status" do
    setup do
      DummyTransportPerformer.any_instance.stubs(:connections).returns(stub :get_connection => stub_everything(:failures => 1))

      logger = Logger.new(STDERR)
      logger.level = Logger::DEBUG
      DummyTransportPerformer.any_instance.stubs(:logger).returns(logger)
      @block = Proc.new { |c, u| puts "ERROR" }
    end

    should "not retry when the status code does not match" do
      @transport = DummyTransportPerformer.new :options => { :retry_on_status => 500 }
      assert_equal [500], @transport.instance_variable_get(:@retry_on_status)

      @block.expects(:call).
             returns(Pandora::Transport::Transport::Response.new 400, 'Bad Request').
             times(1)

      @transport.logger.
          expects(:warn).
          with( regexp_matches(/Attempt \d to get response/) ).
          never

      assert_raise Pandora::Transport::Transport::Errors::BadRequest do
        @transport.perform_request('GET', '/', &@block)
      end
    end

    should "retry when the status code does match" do
      @transport = DummyTransportPerformer.new :options => { :retry_on_status => 500 }
      assert_equal [500], @transport.instance_variable_get(:@retry_on_status)

      @block.expects(:call).
             returns(Pandora::Transport::Transport::Response.new 500, 'Internal Error').
             times(4)

      @transport.logger.
          expects(:warn).
          with( regexp_matches(/Attempt \d to get response/) ).
          times(4)

      assert_raise Pandora::Transport::Transport::Errors::InternalServerError do
        @transport.perform_request('GET', '/', &@block)
      end
    end
  end  unless RUBY_1_8

  context "logging" do
    setup do
      @transport = DummyTransportPerformer.new :options => { :logger => Logger.new('/dev/null') }

      fake_connection = stub :full_url => 'localhost:9188/v5/repos/miscellanea/search?size=1',
                             :host     => 'localhost',
                             :connection => stub_everything,
                             :failures => 0,
                             :healthy! => true

      @transport.stubs(:get_connection).returns(fake_connection)
      @transport.serializer.stubs(:load).returns 'foo' => 'bar'
      @transport.serializer.stubs(:dump).returns '{"foo":"bar"}'
    end

    should "log the request and response" do
      @transport.logger.expects(:info).  with do |line|
        line =~ %r|POST localhost\:9188/v5/repos/miscellanea/search\?size=1 \[status\:200, request:.*s, query:n/a\]|
      end
      @transport.logger.expects(:debug). with '> {"foo":"bar"}'
      @transport.logger.expects(:debug). with '< {"foo":"bar"}'

      @transport.perform_request 'POST', 'v5/repos/miscellanea/search', {:size => 1}, {:foo => 'bar'} do
                   Pandora::Transport::Transport::Response.new 200, '{"foo":"bar"}'
                 end
    end

    should "sanitize password in the URL" do
      fake_connection = stub :full_url => 'http://user:password@localhost:9188/v5/repos/miscellanea/search?size=1',
                             :host     => 'localhost',
                             :connection => stub_everything,
                             :failures => 0,
                             :healthy! => true
      @transport.stubs(:get_connection).returns(fake_connection)

      @transport.logger.expects(:info).with do |message|
        assert_match /http:\/\/user:\*{1,15}@localhost\:9188/, message
        true
      end


      @transport.perform_request('GET', '/') {Pandora::Transport::Transport::Response.new 200, '{"foo":"bar"}' }
    end

    should "log a failed Pandora request as fatal" do
      @block = Proc.new { |c, u| puts "ERROR" }
      @block.expects(:call).returns(Pandora::Transport::Transport::Response.new 500, 'ERROR')

      @transport.expects(:__log)
      @transport.logger.expects(:fatal)

      assert_raise Pandora::Transport::Transport::Errors::InternalServerError do
        @transport.perform_request('POST', 'v5/repos/miscellanea/search', &@block)
      end
    end unless RUBY_1_8

    should "not log a failed Pandora request as fatal" do
      @block = Proc.new { |c, u| puts "ERROR" }
      @block.expects(:call).returns(Pandora::Transport::Transport::Response.new 500, 'ERROR')

      @transport.expects(:__log).once
      @transport.logger.expects(:fatal).never

      # No `BadRequest` error
      @transport.perform_request('POST', 'v5/repos/miscellanea/search', :ignore => 500, &@block)
    end unless RUBY_1_8

    should "log and re-raise a Ruby exception" do
      @block = Proc.new { |c, u| puts "ERROR" }
      @block.expects(:call).raises(Exception)

      @transport.expects(:__log).never
      @transport.logger.expects(:fatal)

      assert_raise(Exception) { @transport.perform_request('POST', 'v5/repos/miscellanea/search', &@block) }
    end unless RUBY_1_8
  end

  context "tracing" do
    setup do
      @transport = DummyTransportPerformer.new :options => { :tracer => Logger.new('/dev/null') }

      fake_connection = stub :full_url => 'localhost:9188/v5/repos/miscellanea/search?size=1',
                             :host     => 'localhost',
                             :connection => stub_everything,
                             :failures => 0,
                             :healthy! => true

      @transport.stubs(:get_connection).returns(fake_connection)
      @transport.serializer.stubs(:load).returns 'foo' => 'bar'
      @transport.serializer.stubs(:dump).returns <<-JSON.gsub(/^      /, '')
      {
        "foo" : {
          "bar" : {
            "bam" : true
          }
        }
      }
      JSON
    end

    should "trace the request" do
      @transport.tracer.expects(:info).with do |message|
        message == <<-CURL.gsub(/^            /, '')
            curl -X POST 'http://localhost:9188/v5/repos/miscellanea/search?size=1' -d '{
              "foo" : {
                "bar" : {
                  "bam" : true
                }
              }
            }
            '
          CURL
      end.once

      @transport.perform_request 'POST', 'v5/repos/miscellanea/search', {:size => 1}, {:q => 'foo'} do
                   Pandora::Transport::Transport::Response.new 200, '{"foo":"bar"}'
                 end
    end

    should "trace a failed Pandora request" do
      @block = Proc.new { |c, u| puts "ERROR" }
      @block.expects(:call).returns(Pandora::Transport::Transport::Response.new 500, 'ERROR')

      @transport.expects(:__trace)

      assert_raise Pandora::Transport::Transport::Errors::InternalServerError do
        @transport.perform_request('POST', 'v5/repos/miscellanea/search', &@block)
      end
    end unless RUBY_1_8

  end

  context "rebuild connections" do
    setup do
      @transport = DummyTransport.new :options => { :logger => Logger.new('/dev/null') }
    end

    should "keep existing connections" do
      @transport.__rebuild_connections :hosts => [ { :host => 'node1', :port => 1 } ], :options => { :http => {} }
      assert_equal 1, @transport.connections.size

      old_connection_id = @transport.connections.first.object_id

      @transport.__rebuild_connections :hosts => [ { :host => 'node1', :port => 1 },
                                                   { :host => 'node2', :port => 2 } ],
                                       :options => { :http => {} }

      assert_equal 2, @transport.connections.size
      assert_equal old_connection_id, @transport.connections.first.object_id
    end

    should "remove dead connections" do
      @transport.__rebuild_connections :hosts => [ { :host => 'node1', :port => 1 },
                                                   { :host => 'node2', :port => 2 } ],
                                       :options => { :http => {} }
      assert_equal 2, @transport.connections.size

      @transport.connections[1].dead!

      @transport.__rebuild_connections :hosts => [ { :host => 'node1', :port => 1 } ], :options => { :http => {} }

      assert_equal 1, @transport.connections.size
      assert_equal 1, @transport.connections.all.size
    end
  end

  context "rebuilding connections" do
    setup do
      @transport = DummyTransport.new
    end

    should "close connections" do
      @transport.expects(:__close_connections)
      @transport.__rebuild_connections :hosts => [ { :scheme => 'http', :host => 'foo', :port => 1 } ], :options => { :http => {} }
    end

    should "should replace the connections" do
      assert_equal 0, @transport.connections.size

      @transport.__rebuild_connections :hosts => [{ :scheme => 'http', :host => 'foo', :port => 1 }],
                                       :options => { :http => {} }

      assert_equal 1, @transport.connections.size
    end
  end

  context "resurrecting connections" do
    setup do
      @transport = DummyTransportPerformer.new
    end

    should "delegate to dead connections" do
      @transport.connections.expects(:dead).returns([])
      @transport.resurrect_dead_connections!
    end

    should "not resurrect connections until timeout" do
      @transport.connections.expects(:get_connection).returns(stub_everything :failures => 1).times(5)
      @transport.expects(:resurrect_dead_connections!).never
      5.times { @transport.get_connection }
    end

    should "resurrect connections after timeout" do
      @transport.connections.expects(:get_connection).returns(stub_everything :failures => 1).times(5)
      @transport.expects(:resurrect_dead_connections!)

      4.times { @transport.get_connection }

      now = Time.now + 60*2
      Time.stubs(:now).returns(now)

      @transport.get_connection
    end

    should "mark connection healthy if it succeeds" do
      c = stub_everything(:failures => 1)
      @transport.expects(:get_connection).returns(c)
      c.expects(:healthy!)

      @transport.perform_request('GET', '/') { |connection, url| Pandora::Transport::Transport::Response.new 200, 'OK' }
    end
  end

  context "errors" do
    should "raise highest-level Error exception for any ServerError" do
      assert_kind_of Pandora::Transport::Transport::Error, Pandora::Transport::Transport::ServerError.new
    end
  end

  context "signing request" do
    setup do
      DummyTransport.any_instance.stubs(:connections).returns(stub :get_connection => stub_everything(:failures => 1, :connection => stub_everything(:headers => {})))
	  @block = Proc.new { |c, u| }
	  Time.stubs(:now).returns(Time.at(1498000000))
    end

    should "not sign request when ak & sk is not provided" do
      @transport = DummyTransport.new

      @block.expects(:call).
		     with do |c, u|
		       c.connection.headers['Date'] == nil
		       c.connection.headers['Authorization'] == nil
		     end.
             returns(Pandora::Transport::Transport::Response.new 200, 'OK').
		     times(1)

      @transport.perform_request('GET', '/', &@block)
	end

	should "sign request when ak & sk is provided" do
      @transport = DummyTransport.new :options => { :ak => 'fake_ak', :sk => 'fake_sk' }
      assert_equal 'fake_ak', @transport.instance_variable_get(:@ak)
      assert_equal 'fake_sk', @transport.instance_variable_get(:@sk)

      @block.expects(:call).
		     with do |c, u|
		       c.connection.headers['Date'] == 'Tue, 20 Jun 2017 23:06:40 GMT' 
		       c.connection.headers['Authorization'] == 'Pandora fake_ak:0kb0YRduDmqCbyFAa1zQIy2DMSc='
		     end.
             returns(Pandora::Transport::Transport::Response.new 200, 'OK').
			 times(1)

      @transport.perform_request('GET', '/', &@block)
	end
  end
end
