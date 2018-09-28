# encoding: UTF-8

require 'test_helper'

module Logdb
  module Test
    class APITest < ::Test::Unit::TestCase

      context "The API module" do

        should "access the settings" do
          assert_not_nil Logdb::API.settings
        end

        should "allow to set settings" do
          assert_nothing_raised { Logdb::API.settings[:foo] = 'bar' }
          assert_equal 'bar', Logdb::API.settings[:foo]
        end

        should "have default serializer" do
          assert_equal MultiJson, Logdb::API.serializer
        end

      end

    end
  end
end
