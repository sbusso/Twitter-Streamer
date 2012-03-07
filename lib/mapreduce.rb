require "rubygems"
require 'mongo'
require 'yaml'

config = YAML.load_file("#{File.expand_path(File.dirname(__FILE__))}/../config/twitter_streamer.yml")
db = Mongo::Connection.new.db("twitter_streamer")

map = "function () {
    emit(this.source, 1);
}"

reduce = "function (key, values) {
    var count = 0;
    values.forEach(function (v) {count += 1;});
    return {key: key, count:count};
}"

db.collection("tweets_12409352").mapreduce(map, reduce, :out => 'out')

db.collection('out').find.each do |o|
  p o
end
