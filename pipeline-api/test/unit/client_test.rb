require 'test_helper'

module Pipeline
  module Test
    class ClientTest < ::Test::Unit::TestCase

      context "API Client" do

        class MyDummyClient
          include Pipeline::API
        end

        subject { MyDummyClient.new }

        should "have the repos namespace" do
          assert_respond_to subject, :repos
        end

		should "have the exports namespace" do
          assert_respond_to subject, :exports
        end

        should "have the data namespace" do
          assert_respond_to subject, :data
        end

      end

    end
  end
end
