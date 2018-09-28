module Pipeline
  module API
    module Exports 
      module Actions; end

      # Client for the "exports" namespace (includes the {Exports::Actions} methods)
      #
      class ExportsClient
        include Common::Client, Common::Client::Base, Exports::Actions
      end

      # Proxy method for {ExportsClient}, available in the receiving object
      #
      def exports
        @exports ||= ExportsClient.new(self)
      end

    end
  end
end
