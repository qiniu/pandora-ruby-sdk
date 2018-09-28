require 'test_helper'

module Logdb
  module Test
    class ClientTest < ::Test::Unit::TestCase

      context "API Client" do

        class MyDummyClient
          include Logdb::API
        end

        subject { MyDummyClient.new }

        should "have the repos namespace" do
          assert_respond_to subject, :repos
        end

        should "have the data namespace" do
          assert_respond_to subject, :data
        end

      end

    end
  end
end
