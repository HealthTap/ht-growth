require_relative './app'

map '/api/guest/' do
  run App
end
