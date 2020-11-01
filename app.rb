require 'pry'

require 'active_record'
require 'mysql2'
require 'sinatra'
require 'sinatra/reloader'
require 'dotenv'
Dotenv.load

require 'config'
register Config

env = ENV.fetch('ENVIRONMENT') { 'sample' }
Config.load_and_set_settings(Config.setting_files("./config/", env))
Settings.add_source!({env: env})
Settings.reload!

Dir['./lib/**/*.rb'].each do |f|
  require_relative f
end

require_relative 'routes'
require_relative 'connection'
