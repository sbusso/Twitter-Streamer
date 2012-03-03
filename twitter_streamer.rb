require "rubygems"
require "bundler/setup"
Bundler.require

require 'logger'
require 'yaml'

config = YAML.load_file("twitter_streamer.yml")

Logger.new('tmp/twitter_streamer.log', 'daily')

TweetStream.configure do |ts|
  ts.consumer_key = config['APPS_TOKEN']['consumer_key']
  ts.consumer_secret = config['APPS_TOKEN']['consumer_secret']
  ts.oauth_token = config['USER_TOKEN']['oauth_token']
  ts.oauth_token_secret = config['USER_TOKEN']['oauth_token_secret']
  ts.auth_method = :oauth
  ts.parser   = :yajl
end

twitter_user_id = config['USER_TOKEN']['oauth_token'].scan(/^(\d+)-/).first.first

db = Mongo::Connection.new(config['MONGODB']['host']).db(config['MONGODB']['db'])
tweets = db.collection("tweets_#{twitter_user_id}")

daemon = TweetStream::Daemon.new(ENV['DAEMON_NAME'] || 'streamer', :dir => ENV['PIDS'] || 'tmp')

daemon.on_error do |message|
  logger.error message
end

# daemon.on_direct_message do |direct_message|
#   puts direct_message.text
# end

# daemon.on_reconnect do |timeout, retries|
#
# end

daemon.on_timeline_status  do |status|
  tweets.insert(status)
end

daemon.userstream