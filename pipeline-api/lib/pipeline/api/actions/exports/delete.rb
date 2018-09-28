module Pipeline 
  module API
    module Exports 
      module Actions

        def delete(arguments={})
          raise ArgumentError, "Required argument 'repo' missing" unless arguments[:repo]
          raise ArgumentError, "Required argument 'export' missing" unless arguments[:export]
          valid_params = []

          method = HTTP_DELETE
          path   = Utils.__pathify 'v2/repos', Utils.__listify(arguments[:repo]), 'exports', Utils.__listify(arguments[:export])
          params = Utils.__validate_and_extract_params arguments, valid_params
          body   = nil 

          if Array(arguments[:ignore]).include?(404)
            Utils.__rescue_from_not_found { 
			  perform_request method, path, params, body do |connection|
				connection.connection.headers['Content-Type'] = 'application/json'
			  end
			}
          else
            perform_request method, path, params, body do |connection|
			  connection.connection.headers['Content-Type'] = 'application/json'
			end
          end
        end
      end
    end
  end
end
