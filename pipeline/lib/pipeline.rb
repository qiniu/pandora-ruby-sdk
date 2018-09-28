require "pipeline/version"

require 'pandora/transport'
require 'pipeline/api'

module Pipeline
  class Client < Pandora::Transport::Client
    include Pipeline::API
  end
end
