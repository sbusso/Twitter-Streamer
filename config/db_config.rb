require "rubygems"
require 'mongo'
require 'yaml'

config = YAML.load_file("#{File.expand_path(File.dirname(__FILE__))}/twitter_streamer.yml")
db = Mongo::Connection.new.db("twitter_streamer")
