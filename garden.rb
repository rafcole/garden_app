require "yaml"
require 'date'

require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "bcrypt"

require_relative 'custom_classes/garden_class'

# session needs in app?
configure do
  enable :sessions
  set :session_secret, 'super secret'
end

# this is where the id_209384.yml files for inidividual users will live
def user_data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/user_data", __FILE__)
    # all_users.yml
    # id_23423.yml
    # id_87837.yml ...
  else
    File.expand_path("../user_data", __FILE__)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/user_data/all_users.yml", __FILE__)
  else
    File.expand_path("../user_datea/all_users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def valid_credentials?(user_name, password)
  user_hash = load_user_credentials

  if user_hash[user_name]
    puts user_hash.to_s
    password_from_file = BCrypt::Password.new(user_hash[user_name]["password")
    password_from_file == password
  else
    false
  end
end

# homepage
get "/" do
  erb :home
end

# sign in
get "/signin" do 
  if session[:user]
    session[:message] = "You are currently signed in as #{session[:user]}. <a href=/signout> Click here to signout</a>"
    redirect "/"
  end

  erb :signin
end

# sign in post
post "/signin" do
  user_name = params["username"]
  password = params["password"]
  # if the password is correct, allow log in
  if valid_credentials?(user_name, password)
    session[:user] = user_name
    session[:message] = "Welcome #{params["username"]}"
    redirect "/"
  else
    status 422
    session[:message] = "log in failed - generic"
    erb :signin
  end
end

def require_signed_in_user
  if session[:user].nil? 
    session[:message] = "You must be signed in to do that"
    redirect "/"
  end
end

get "/signout" do
  require_signed_in_user
  # require signed in user
  session[:user] = nil 
  session[:message] = "You have signed out successfully"
  redirect "/"
end

# sign up
get "/signup" do
  erb :signup
end

# submit sign up
post "/signup" do

end

# add/remove garden page
get "/add-garden" do
end


get "/edit-garden" do
  erb :edit_gardens
end

# submit data to add/remove garden
post "/edit-garden" do
  erb :edit_gardens
end