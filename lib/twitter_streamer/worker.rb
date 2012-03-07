require "rubygems"
require 'yajl'
require 'tweetstream'
require 'mongo'
require 'logger'
require 'yaml'

module TwitterStreamer
  class Worker
    def self.perform(uid, oauth_token, oauth_token_secret)
      config = YAML.load_file("#{File.expand_path(File.dirname(__FILE__))}/../../config/twitter_streamer.yml")
      logger = Logger.new("#{File.expand_path(File.dirname(__FILE__))}/../../tmp/twitter_streamer.log", 'daily')
      logger.info("starting streaming of #{uid}")
      TweetStream.configure do |ts|
        ts.consumer_key = config['APPS_TOKEN']['consumer_key']
        ts.consumer_secret = config['APPS_TOKEN']['consumer_secret']
        ts.oauth_token = oauth_token
        ts.oauth_token_secret = oauth_token_secret
        ts.auth_method = :oauth
        ts.parser   = :yajl
      end

      db = Mongo::Connection.new(config['MONGODB']['host']).db(config['MONGODB']['db'])
      tweets = db.collection("tweets_#{uid}")

      client = TweetStream::Client.new#("streamer_#{uid}", :dir => ENV['PIDS'] || 'tmp')

      client.on_error do |message|
        logger.error message
      end

      # daemon.on_direct_message do |direct_message|
      #   puts direct_message.text
      # end

      # daemon.on_delete do |status_id, user_id|
      #   flag the tweet as deleted
      # end


      # daemon.on_reconnect do |timeout, retries|
      #
      # end

      client.on_timeline_status  do |status|
        tweets.insert(status)
      end

      client.userstream
    end

    def self.start(uid, token, secret)
      pid = fork { TwitterStreamer::Worker.perform(uid, token, secret) }
      Process.detach(pid)
      return pid
    end

    def self.stop(pid)
      Process.kill("TERM", pid)
    end
  end
end
