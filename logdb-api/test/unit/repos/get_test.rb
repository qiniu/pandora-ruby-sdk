require 'test_helper'

module Logdb
  module Test
    class ReposGetTest < ::Test::Unit::TestCase

      context "Repos: Get" do
        subject { FakeClient.new }

        should "require the :repo argument" do
          assert_raise ArgumentError do
            subject.repos.get
          end
        end

        should "perform correct request" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'GET', method
            assert_equal 'v5/repos/foo', url
            assert_equal Hash.new, params
            assert_nil   body
          end.returns(FakeResponse.new)

          subject.repos.get :repo => 'foo'
        end

        should "URL-escape the parts" do
          subject.expects(:perform_request).with do |method, url, params, body|
            assert_equal 'GET', method
            assert_equal 'v5/repos/foo%5Ebar', url
          end.returns(FakeResponse.new)

          subject.repos.get :repo => 'foo^bar'
        end

      end

    end
  end
end
