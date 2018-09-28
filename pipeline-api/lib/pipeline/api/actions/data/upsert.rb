module Pipeline 
  module API
    module Data 
      module Actions
        
        def upsert(arguments={})
          raise ArgumentError, "Required argument 'repo' missing" unless arguments[:repo]
          valid_params = []

          method = HTTP_POST 
          path   = Utils.__pathify 'v2/repos', Utils.__escape(arguments[:repo]), 'data'
          params = Utils.__validate_and_extract_params arguments, valid_params
		  body   = Utils.__format_data arguments[:body]

          if Array(arguments[:ignore]).include?(404)
            Utils.__rescue_from_not_found { 
			  perform_request method, path, params, body do |connection|
				connection.connection.headers['Content-Type'] = 'application/text'
			  end
			}
          else
            perform_request method, path, params, body do |connection|
			  connection.connection.headers['Content-Type'] = 'application/text'
			end
          end
        end
      end
    end
  end
end
