require 'test_helper'

require 'jbuilder' if defined?(RUBY_VERSION) && RUBY_VERSION > '1.9'
require 'jsonify'

module Logdb
  module Test
    class JsonBuildersTest < ::Test::Unit::TestCase

      context "JBuilder" do
        subject { FakeClient.new }

        should "build a JSON" do
          subject.expects(:perform_request).with do |method, url, params, body|
            json = MultiJson.load(body)

            assert_instance_of String, body
			assert_equal       'timestamp', json['schema'].first['key']
            true
          end.returns(FakeResponse.new)

		  schemas = [{:key => :timestamp, :valtype => :long, :analyzer => :space}]
          json = Jbuilder.encode do |json|
                   json.schema do
                     json.array!(schemas) do |schema|
						 json.key      schema[:key]
						 json.valtype  schema[:valtype]
						 json.analyzer schema[:analyzer] 
                     end
                   end
                 end

		  subject.repos.create :repo => 'foo', :body => json
        end
      end if defined?(RUBY_VERSION) && RUBY_VERSION > '1.9'

      context "Jsonify" do
        subject { FakeClient.new }

        should "build a JSON" do
          subject.expects(:perform_request).with do |method, url, params, body|
            json = MultiJson.load(body)

            assert_instance_of String, body
			assert_equal       'timestamp', json['schema'].first['key']
            true
          end.returns(FakeResponse.new)

		  schemas = [{:key => :timestamp, :valtype => :long, :analyzer => :space}]
          json = Jsonify::Builder.compile do |json|
                   json.schema do
                     json.array!(schemas) do |schema|
						 json.key      schema[:key]
						 json.valtype  schema[:valtype]
						 json.analyzer schema[:analyzer] 
                     end
                   end
                 end

		  subject.repos.create :repo => 'foo', :body => json
        end
      end

    end
  end
end
