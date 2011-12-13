require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'omniauth/facebook'

enable :sessions
use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_SECRET'], :scope => "read_friendlists,manage_friendlists"
end

helpers do
  def current_user
    session[:name]
  end
end

get '/' do
  redirect "/defriend" if current_user
  haml :index
end

get '/auth/facebook/callback' do
  auth = request.env['omniauth.auth']
  session[:token] = auth.credentials.token
  session[:name] = auth.info.name
  redirect '/defriend'
end

get "/defriend" do
  authenticate_user!
  haml :defriend
end

post "/defriend" do
  user = FbGraph::User.me(session[:token]).fetch
  acq_list = user.friend_lists.reject {|fl| fl.name != "Acquaintances"}.first
  user.friends.each do |friend|
    acq_list.member! FbGraph::User.new(friend.identifier)
  end
  haml :defriended
end

get '/logout' do
  session[:token] = session[:name] = nil
  redirect "/"
end

private
  def authenticate_user!
    redirect '/' unless session[:token]
  end