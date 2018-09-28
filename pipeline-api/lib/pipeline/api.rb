require "cgi"
require "multi_json"

require "pipeline/api/version"
require "pipeline/api/namespace/common"
require "pipeline/api/utils"

Dir[ File.expand_path('../api/actions/**/*.rb', __FILE__) ].each   { |f| require f }
Dir[ File.expand_path('../api/namespace/**/*.rb', __FILE__) ].each { |f| require f }

module Pipeline
  module API
    DEFAULT_SERIALIZER = MultiJson

    COMMON_PARAMS = [
      :ignore,                        # Client specific parameters
      :repo,                          # Repo 
      :export,                        # Export 
      :body                           # Request body
	]
    COMMON_QUERY_PARAMS = [
      :ignore                         # Client specific parameters
	]

    HTTP_GET          = 'GET'.freeze
    HTTP_HEAD         = 'HEAD'.freeze
    HTTP_POST         = 'POST'.freeze
    HTTP_PUT          = 'PUT'.freeze
    HTTP_DELETE       = 'DELETE'.freeze

    # Auto-include all namespaces in the receiver
    #
    def self.included(base)
      base.send :include,
                Pipeline::API::Common,
                Pipeline::API::Repos,
                Pipeline::API::Exports,
                Pipeline::API::Data
    end

    # The serializer class
    #
    def self.serializer
      settings[:serializer] || DEFAULT_SERIALIZER
    end

    # Access the module settings
    #
    def self.settings
      @settings ||= {}
    end
  end
end
