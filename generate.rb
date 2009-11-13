# Author:  Emanuele Tozzato (mailto:etozzato@gmail.com)
# 
# = Description
# Nothing serious here: Just a simple ruby script written in a gray morning to generate a SINATRA application with a basic tree (the way I like it), 
# with an automatic git setup and heroku deployment. It also shotguns the application for you on 0.0.0.0, opens Safari and sends the project to Textmate. 
# Do I need to TELL YOU that this is 100% tailored for my macBook  and you need some gems for it to work (and today I'm too lazy to add more code..) ?
# THANKS! :)
#
# gem required: sinatra, shotgun, heroku
# also required: TextMate, Safari, an account on heroku
#
# = My Application Tree:
#
# Rakefile
# app.rb
# config.ru
# lib.rb
# config/
# database.yml
# db/
#  migrate/
# models/
#  models.rb
# public/
# views/
#
# = Example
# ruby ./SinaTree/generate.rb myapplication git heroku
#
# Creating Sinatra Application myapplication...
# Creating Sinatra Dir...
# Creating Sinatra Tree...
# Creating Sinatra Files...
# Counting objects: 10, done.
# Compressing objects: 100% (8/8), done.
# Writing objects: 100% (10/10), 1.65 KiB, done.
# Total 10 (delta 0), reused 0 (delta 0)
#
# -----> Heroku receiving push
# -----> Sinatra app detected
#       Compiled slug size is 4K
# -----> Launching......... done
#       http://morning-stone-40.heroku.com deployed to Heroku
#
# To git@heroku.com:morning-stone-40.git
# * [new branch]      master -> master
# Sending to TextMate
# Starting application on port 3030..
# Sending to Safari
#
# E/T +searchintegrate.com +mekdigital.com +trueinteractive.net

## TEMPLATES
app_rb = 'require "rubygems"
require "sinatra"

enable :sessions

configure do
  require "active_record"
  require "yaml"
  require "./models/models.rb"
  require "./lib.rb"
  include Lib
  ar_init
end

get "/" do
  version
end'

config_ru = 'require "rubygems"
require "sinatra"

set :environment, :production
set :root, File.dirname(__FILE__)
set :run, false

set :app_file, __FILE__

require "app.rb"
run Sinatra::Application'

rakefile = 'require "rubygems"
require "active_record"
require "yaml"
require "rake"
require "./lib.rb"

include Lib
ar_init

namespace :db do
  desc "MIGRATE"
  task :migrate do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
    # push live after migration 
    `heroku db:push mysql://root@localhost/APP_NAME`
  end
end'

lib_rb = 'module Lib

  def ar_init
    if defined?(production) && production?
      config = YAML.load(File.read("config/database.yml"))
      ActiveRecord::Base.establish_connection(config["production"])
    else
      config = YAML::load(IO.read(File.dirname(__FILE__) + "/database.yml"))
      ActiveRecord::Base.establish_connection(config["development"])
    end
    ActiveRecord::Base.default_timezone = :utc
  end
  
  helpers do

    def protected!
      response[\'WWW-Authenticate\'] = %(Basic realm="HTTP Auth") and \
      throw(:halt, [401, "Not authorized\n"]) and \
      return unless authorized?
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [\'admin\', \'admin\']
    end

  end

  def version
    "Running on Sinatra #{Sinatra::VERSION}<br /><br />Generated with <a href=\"http://github.com/etozzato/SinaTree\">SinaTree</a> by <a href=\"http://searchintegrate.com\">SearchIntegrate Labs</a> <br /><br /><script language=\"javascript\" src=\"http://app.headcounters.com/digits.js\"></script>"
  end
  
end'

models_rb = '[].each do |model|
  require "./models/#{model}.rb"
end'

database_yml = 'development:
  adapter: mysql
  encoding: utf8
  database: APP_NAME
  username: root
  password:
  host: localhost'
##

unless ARGV[0]
  raise StandardError.new('Usage: ruby ./sinatra.rb APP_NAME')
else
  name = ARGV[0]
  puts "Creating Sinatra Application #{name}..."
  unless File.exists?(name)
    `mkdir #{name}`
    puts "Creating Sinatra Dir..."
    `cd #{name} && mkdir models && mkdir public && mkdir views && mkdir db && mkdir db/migrate && mkdir config`
    puts "Creating Sinatra Tree..."
    `cd #{name} && echo '#{app_rb}' >> app.rb && echo '#{config_ru}' >> config.ru && echo '#{rakefile.gsub('APP_NAME', name + '_db')}' >> Rakefile && echo '#{lib_rb}' >> lib.rb && echo '#{models_rb}' >> models/models.rb && echo '#{database_yml.gsub('APP_NAME', name + '_db')}' >> database.yml`
    puts "Creating Sinatra Files..."
    
    if ARGV.include?('git')
      `cd #{name} && git init && git add . && git commit -a -m 'my first commit'`
      
      if ARGV.include?('heroku')
        `cd #{name} && heroku create && git push heroku master`
      end
    end
    
    puts "Sending to TextMate"
    `cd #{name} && mate . &`
    
    puts "Starting application on port 3030.."
    puts "Sending to Safari"
    
    `cd #{name} && shotgun app.rb -p 3030 &`
    `open -a Safari 'http://localhost:3030' &`
  else
    raise StandardError.new("Error: Application #{name} Found!")
  end
end