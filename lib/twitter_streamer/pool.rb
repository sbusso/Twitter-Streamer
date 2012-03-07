#!/usr/bin/env ruby
require 'rubygems'
require 'daemon_spawn'
require 'eventmachine'
require './lib/twitter_streamer/worker'
require 'mongoid'
require './lib/models/user'

module TwitterStreamer
  class Server < EventMachine::Connection
    attr_accessor :options, :status

    def receive_data(data)
        puts "#{@status} -- #{data}"
        send_data("helo\n")
    end
  end


  class Pool < DaemonSpawn::Base



    def start(args)
      config = YAML.load_file("#{File.expand_path(File.dirname(__FILE__))}/../../config/twitter_streamer.yml")
      db = Mongo::Connection.new.db("twitter_streamer")
      Mongoid.configure do |config|
        config.master = db
      end
      User.all.each do |current_user|
        current_user.pid = TwitterStreamer::Worker.start(current_user.uid, current_user.token, current_user.secret)
        current_user.save
      end

      EM.run do
        # check users
        # check connection
        # restart dead pids
        # start streamer for new user
        EM.start_server 'localhost', 8080, Server do |conn|
          # conn.options = {:my => 'options'}
          conn.status = :OK
        end
      end
    end

    def stop
      User.all.each do |current_user|
        Process.kill('TERM', current_user.pid)
        current_user.pid = nil
        current_user.save
      end
    end
  end
end

TwitterStreamer::Pool.spawn!({
  :log_file => File.join("log", "twitter_streamer_pool.log"),
  :pid_file => File.join('tmp', 'pids', 'twitter_streamer_pool.pid'),
  :sync_log => true,
  :working_dir => './',
  :singleton => true
})


# (12409352, '12409352-UWHIbww6NbzN0sBdN2KGRpwAXnyUC8Mpo3nYgs3Nt', 'egpEFEy5jVnKFyouHSJFRZvGM90mDaw3rwInes4AcM')