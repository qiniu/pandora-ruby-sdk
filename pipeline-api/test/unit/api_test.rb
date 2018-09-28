# encoding: UTF-8

require 'test_helper'

module Pipeline
  module Test
    class APITest < ::Test::Unit::TestCase

      context "The API module" do

        should "access the settings" do
          assert_not_nil Pipeline::API.settings
        end

        should "allow to set settings" do
          assert_nothing_raised { Pipeline::API.settings[:foo] = 'bar' }
          assert_equal 'bar', Pipeline::API.settings[:foo]
        end

        should "have default serializer" do
          assert_equal MultiJson, Pipeline::API.serializer
        end

      end

    end
  end
end
