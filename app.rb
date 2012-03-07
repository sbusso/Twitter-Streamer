require 'rubygems'
require 'sinatra'
require 'multi_json'
require 'omniauth'
require 'omniauth-twitter'
require 'haml'
require 'yaml'
require 'logger'
require 'mongoid'
require './lib/twitter_streamer/worker'
require './lib/models/user'



# require 'rack-flash'



config = YAML.load_file("config/twitter_streamer.yml")
logger = Logger.new('tmp/twitter_streamer_server.log', 'daily')

use Rack::Session::Cookie
# use Rack::Flash
use OmniAuth::Builder do
  provider :twitter, config['APPS_TOKEN']['consumer_key'], config['APPS_TOKEN']['consumer_secret']
end

# Mongoid.load!("config/mongoid.yml")

db = Mongo::Connection.new.db("twitter_streamer")

Mongoid.configure do |config|
  config.master = db
  config.logger = logger
end

helpers do
  def current_user
    begin
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    rescue Mongoid::Errors::DocumentNotFound
      nil
    end
  end

  def user_signed_in?
    return true if current_user
  end

  def authenticate_user!
    if !current_user
      redirect '/'
    end
  end

  def running?(pid = current_user.pid)
    if pid
      Daemons::Pid.running?(pid)
    else
      false
    end
  end
end

get '/' do
  @tweets = current_user.tweets.find.sort('_id', -1).limit(25) if current_user
  haml :index
end

get '/auth/:name/callback' do
  auth = request.env["omniauth.auth"]
  user = User.where(:provider => auth['provider'], :uid => auth['uid']).first || User.create_with_omniauth(auth)
  session[:user_id] = user.id
  # flash.now[:notice] = "Sign in!"
  redirect '/'
end

get '/auth/failure' do
  "Oups something went wrong !"
end

get '/users' do
  @users = User.all
  haml :users
end

get '/user/:id' do
  @user = User.find(params[:id])

end

get '/start' do
  current_user.pid = TwitterStreamer::Worker.start(current_user.uid, current_user.token, current_user.secret)
  current_user.save
  redirect '/'
end

get '/stop' do
  TwitterStreamer::Worker.stop(current_user.pid)
  current_user.pid = nil
  current_user.save
  redirect '/'
end



["/sign_in/?", "/signin/?", "/log_in/?", "/login/?", "/sign_up/?", "/signup/?"].each do |path|
  get path do
    redirect '/auth/twitter'
  end
end

["/sign_out/?", "/signout/?", "/log_out/?", "/logout/?"].each do |path|
  get path do
    session[:user_id] = nil
    # flash.now[:notice] = "Sign out!"
    redirect '/'
  end
end