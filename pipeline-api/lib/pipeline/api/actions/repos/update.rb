module Pipeline 
  module API
    module Repos 
      module Actions

        def update(arguments={})
          raise ArgumentError, "Required argument 'repo' missing" unless arguments[:repo]
          valid_params = []

          method = HTTP_PUT
          path   = Utils.__pathify 'v2/repos', Utils.__listify(arguments[:repo])
          params = Utils.__validate_and_extract_params arguments, valid_params
          body   = arguments[:body]

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
