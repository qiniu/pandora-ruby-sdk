require 'test_helper'

module Pipeline
  module Test
    class ExportsCreateTest < ::Test::Unit::TestCase

      context "Exports: Create" do
        subject { FakeClient.new }

        should "require the :repo argument" do
          assert_raise ArgumentError do
            subject.exports.create
          end
        end

        should "perform correct request" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
            assert_equal 'v2/repos/foo/exports/bar', url
            assert_equal Hash.new, params
            assert_nil   body
          end.returns(FakeResponse.new)

          subject.exports.create :repo => 'foo', :export => 'bar'
        end

        should "pass the URL parameters" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
            assert_equal 'v2/repos/foo/exports/bar', url
            assert_equal '{"timestamp": 1497439915}', body 
          end.returns(FakeResponse.new)

          subject.exports.create :repo => 'foo', :export => 'bar', :body => '{"timestamp": 1497439915}'
        end

        should "URL-escape the parts" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
            assert_equal 'v2/repos/foo%5Ebar/exports/bar%5Efoo', url
          end.returns(FakeResponse.new)

          subject.exports.create :repo => 'foo^bar', :export => 'bar^foo'
        end

      end

    end
  end
end
