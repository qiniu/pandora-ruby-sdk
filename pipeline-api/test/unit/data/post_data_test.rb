require 'test_helper'

module Pipeline
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
            assert_equal 'v2/repos/foo/data', url
            assert_equal Hash.new, params
            assert_equal "", body
          end.returns(FakeResponse.new)

          subject.data.upsert :repo => 'foo'
        end

        should "pass the URL parameters" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
            assert_equal 'v2/repos/foo/data', url
            assert_equal 'timestamp=1497439915	log=test', body 
          end.returns(FakeResponse.new)

          subject.data.upsert :repo => 'foo', :body => [{"timestamp" => 1497439915, "log" => "test"}]
        end

        should "URL-escape the parts" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
			assert_equal 'v2/repos/foo%5Ebar/data', url
          end.returns(FakeResponse.new)

          subject.data.upsert :repo => 'foo^bar'
        end

      end

    end
  end
end
