require 'pry'

require 'active_record'
require 'mysql2'
require 'sinatra'
require 'sinatra/reloader'

require 'config'
register Config

Dir['./lib/**/*.rb'].each do |f|
  require_relative f
end

require_relative 'routes'
require_relative 'connection'
