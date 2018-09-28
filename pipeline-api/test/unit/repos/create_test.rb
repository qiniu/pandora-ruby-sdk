require 'test_helper'

module Pipeline
  module Test
    class ReposCreateTest < ::Test::Unit::TestCase

      context "Repos: Create" do
        subject { FakeClient.new }

        should "require the :repo argument" do
          assert_raise ArgumentError do
            subject.repos.create
          end
        end

        should "perform correct request" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
            assert_equal 'v2/repos/foo', url
            assert_equal Hash.new, params
            assert_nil   body
          end.returns(FakeResponse.new)

          subject.repos.create :repo => 'foo'
        end

        should "pass the URL parameters" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
            assert_equal 'v2/repos/foo', url
            assert_equal '{"timestamp": 1497439915}', body 
          end.returns(FakeResponse.new)

          subject.repos.create :repo => 'foo', :body => '{"timestamp": 1497439915}'
        end

        should "URL-escape the parts" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'POST', method
            assert_equal 'v2/repos/foo%5Ebar', url
          end.returns(FakeResponse.new)

          subject.repos.create :repo => 'foo^bar'
        end

      end

    end
  end
end
