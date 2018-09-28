module Pipeline
  module API
    module Data 
      module Actions; end

      # Client for the "data" namespace (includes the {Data::Actions} methods)
      #
      class DataClient
        include Common::Client, Common::Client::Base, Data::Actions
      end

      # Proxy method for {DataClient}, available in the receiving object
      #
      def data 
        @data ||= DataClient.new(self)
      end

    end
  end
end
