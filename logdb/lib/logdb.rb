require "logdb/version"

require 'pandora/transport'
require 'logdb/api'

module Logdb
  class Client < Pandora::Transport::Client
    include Logdb::API
  end
end
