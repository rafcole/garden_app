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

###########################################
# def user_data_file_path
    # user_data_path + user_id.yml
    # user_data_path + session_id
# end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/user_data/all_users.yml", __FILE__)
  else
    File.expand_path("../user_data/all_users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def require_signed_in_user
  if session[:user].nil? 
    session[:message] = "You must be signed in to do that"
    redirect "/"
  end
end

def valid_credentials?(user_name, password)
  user_hash = load_user_credentials

  if user_hash[user_name]
    password_from_file = BCrypt::Password.new(user_hash[user_name]["password"])
    password_from_file == password
  else
    false
  end
end

# homepage
get "/" do
  puts session["session_id"]
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

# submit sign in data
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

# signout
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
  # TODO - new users need new user data yamls, relying on hand added usersand data at the moment
  # open users file
  # 
  erb :add_garden
end

def load_user_file
  # do routing for logged in vs not logged in users
  # not signed in site visitor
  #   /user_data/visitors/"#{session_id}.yml
  # signed in user
  #   all_users.yaml["username as string"]["id"]
  #   /user_data/"#{user_id}".yaml
  if session[:user]
    #user_id = load_user_credentials[session[:user]]['id']
    puts "user_id == #{user_id}"
    YAML.load_file(user_data_path + "/#{user_id}.yaml")
  else
    "stuff for session id blah blah"
    path = user_data_path + "/sessions/#{user_id}.yaml"
    YAML.load_file(path)
  end
end

def user_id
  # if a user is logged in, it's the simple id
  # otherwise it's the session id
  if session[:user]
    load_user_credentials[session[:user]]['id']
  else
    session["session_id"]
  end
end

def save_to_user_file(hash_for_yaml)
  path = if session[:user]
           path = user_data_path + "/#{user_id}.yaml"
         else
           path = user_data_path + "/sessions/#{user_id}.yaml"
         end

  contents = hash_for_yaml.to_yaml
  File.open(File.join(path), "w") do |file|
    file.write(contents)
  end
end

def valid_garden_input?(name_str, area_str)
  return false if name_str.strip.size == 0

  area_str.strip!
  if area_str.size > 0
    return false unless area_str.to_i.to_s == area_str
  end

  true
end

post "/add-garden" do
  puts params
  # validate input params
    # error and redirect
  if valid_garden_input?(params["garden_name"], params["area"])
    #success
    garden_name = params["garden_name"]
    area = params["area"].strip.to_i
    # add the garden
    user_data = load_user_file
    user_data["gardens"] << Garden.new(garden_name, area)

    save_to_user_file(user_data)
    # display message
    session[:message] = "Garden added"
    # redirect to homepage
    redirect "/"
  else
    session[:message] = "Invalid input"
    erb :add_garden
  end
end


get "/edit-garden" do
  erb :edit_gardens
end

# submit data to add/remove garden
post "/edit-garden" do
  erb :edit_gardens
end