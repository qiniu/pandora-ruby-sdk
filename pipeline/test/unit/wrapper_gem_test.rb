require 'test_helper'

module Pipeline
  module Test
    class WrapperGemTest < ::Test::Unit::TestCase

      context "Wrapper gem" do

        should "require all neccessary subgems" do
          assert defined? Pipeline::Client
          assert defined? Pipeline::API
        end

        should "mix the API into the client" do
          client = Pipeline::Client.new :transport => :transport

          assert_respond_to client, :data
          assert_respond_to client, :repos
          assert_respond_to client, :exports
        end

      end

    end
  end
end
