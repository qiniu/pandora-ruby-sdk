require 'test_helper'

module Logdb
  module Test
    class ReposDeleteTest < ::Test::Unit::TestCase

      context "Repos: Delete" do
        subject { FakeClient.new }

        should "require the :repo argument" do
          assert_raise ArgumentError do
            subject.repos.delete
          end
        end

        should "perform correct request" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'DELETE', method
            assert_equal 'v5/repos/foo', url
            assert_equal Hash.new, params
            assert_nil   body
          end.returns(FakeResponse.new)

          subject.repos.delete :repo => 'foo'
        end

        should "URL-escape the parts" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'DELETE', method
            assert_equal 'v5/repos/foo%5Ebar', url
          end.returns(FakeResponse.new)

          subject.repos.delete :repo => 'foo^bar'
        end

      end

    end
  end
end
