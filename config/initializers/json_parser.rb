# Fix compatibility between json 3.x and ActionDispatch::Http::Parameters
ActionDispatch::Http::Parameters::DEFAULT_PARSERS[:json] = ->(raw_post) do
  data = JSON.parse(raw_post)
  data.is_a?(Hash) ? data : { _json: data }
end
