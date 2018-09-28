require 'test_helper'

module Logdb
  module Test
    class DataPostTest < ::Test::Unit::TestCase

      context "Data: Post" do
        subject { FakeClient.new }

        should "require the :repo argument" do
          assert_raise ArgumentError do
			  subject.data.upsert
          end
        end

        should "perform correct request" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
            assert_equal 'v5/repos/foo/data', url
            assert_equal Hash.new, params
            assert_nil   body
          end.returns(FakeResponse.new)

          subject.data.upsert :repo => 'foo'
        end

        should "pass the URL parameters" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
            assert_equal 'v5/repos/foo/data', url
            assert_equal '{"timestamp": 1497439915}', body 
          end.returns(FakeResponse.new)

          subject.data.upsert :repo => 'foo', :body => '{"timestamp": 1497439915}'
        end

        should "URL-escape the parts" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
			assert_equal 'v5/repos/foo%5Ebar/data', url
          end.returns(FakeResponse.new)

          subject.data.upsert :repo => 'foo^bar'
        end

      end

    end
  end
end
