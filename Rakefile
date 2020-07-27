require './config/environment'
require 'sinatra/activerecord/rake'

desc 'starts an ActiveRecord logger and opens a console'
task :console do
  ActiveRecord::Base.logger = Logger.new(STDOUT)  
  Pry.start
end