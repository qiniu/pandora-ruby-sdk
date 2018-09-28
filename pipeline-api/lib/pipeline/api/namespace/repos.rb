module Pipeline
  module API
    module Repos
      module Actions; end

      # Client for the "repos" namespace (includes the {Repos::Actions} methods)
      #
      class ReposClient
        include Common::Client, Common::Client::Base, Repos::Actions
      end

      # Proxy method for {ReposClient}, available in the receiving object
      #
      def repos
        @repos ||= ReposClient.new(self)
      end

    end
  end
end
