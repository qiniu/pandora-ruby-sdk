require 'test_helper'

module Logdb
  module Test
    class WrapperGemTest < ::Test::Unit::TestCase

      context "Wrapper gem" do

        should "require all neccessary subgems" do
          assert defined? Logdb::Client
          assert defined? Logdb::API
        end

        should "mix the API into the client" do
          client = Logdb::Client.new :transport => :transport

          assert_respond_to client, :data
          assert_respond_to client, :repos
        end

      end

    end
  end
end
