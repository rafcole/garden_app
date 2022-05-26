require "yaml"
require 'date'

require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "bcrypt"
require "pry"
#require "pry-byebug"

require_relative 'custom_classes/garden_class'

# session needs in app?
configure do
  enable :sessions
  set :session_secret, 'super secret'
end

# this is where the id_209384.yaml files for inidividual users will live
def user_data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/user_data", __FILE__)
    # all_users.yaml
    # id_23423.yaml
    # id_87837.yaml ...
  else
    File.expand_path("../user_data", __FILE__)
  end
end

###########################################
# def user_data_file_path
    # user_data_path + user_id.yaml
    # user_data_path + session_id
# end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
                       File.expand_path("../test/user_data/all_users.yaml", __FILE__)
                     else
                       File.expand_path("../user_data/all_users.yaml", __FILE__)
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
    BCrypt::Password.new(user_hash[user_name]["password"]) == password
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

# submit sign in data
post "/signin" do
  user_name = params["username"]
  password = params["password"]

  # if the password is correct, allow log in
  #binding.pry
  if valid_credentials?(user_name, password)
    session[:user] = user_name
    session[:message] = "Welcome #{user_name}"

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
get "/garden/add" do
  # TODO - new users need new user data yamls, relying on hand added usersand data at the moment
  # open users file
  # 
  erb :add_garden
end

def load_user_file
  # do routing for logged in vs not logged in users
  # not signed in site visitor
  #   /user_data/visitors/"#{session_id}.yaml
  # signed in user
  #   all_users.yaml["username as string"]["id"]
  #   /user_data/"#{user_id}".yaml
  if session[:user]

    YAML.load_file(user_data_path + "/#{user_id}.yaml")
  else
    "stuff for session id blah blah"
    path = user_data_path + "/sessions/#{user_id}.yaml"
    YAML.load_file(path)
  end
end


def load_all_users_file
  # need non /session version for non-existent users AND logged in users

  # if session && session[:user]
  #   #user_id = load_user_credentials[session[:user]]['id']
    YAML.load_file(user_data_path + "/all_users.yaml")
  # else
  #   "stuff for session id blah blah"
  #   # TODO - no tooling for sessions!
  #   path = user_data_path + "/sessions/all_users.yaml"
  #   YAML.load_file(path)
  #   "hello"
  # end
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

# generate id for hashes containing gardens or plantings
# should work for user[:gardens] and garden[:plantings] 
def generate_id(hash)
    return 1 if hash.nil? || hash.empty?

    hash.keys.max + 1
end

def generate_user_id
  highest = load_all_users_file.map do |_k, user_data| 
    _k == "admin" ? 0 : user_data["id"].to_i 
  end.max

  highest + 1
  #highest.nil? ? 1 : highest +1
end

def user_file_content_template
  { "gardens" => {}, "time_created" => Time.now }
end

def create_user(user_name, password)
  # creates new entry in user_data/all_users.yaml
  # creates new file  in user_data/##id.yaml
  # assume pre-validated credentials
  password = BCrypt::Password::create(password)
  id = generate_user_id

  all_users_entry = {
                      "password" => password, 
                      "id" => id
                    }

  add_new_user_to_all_users(user_name, all_users_entry)
  create_user_file(id, user_file_content_template)
end

def create_user_file(id, hsh)
  File.open(File.join(user_data_path + "/#{id}.yaml"), "w") do |file|
    file.write(hsh.to_yaml)
  end
end

def add_new_user_to_all_users(user_name, hsh)
  all_users = load_all_users_file
  all_users[user_name] = hsh

  contents = all_users.to_yaml
  path = user_data_path + "/all_users.yaml"

  File.open(File.join(path), "w") do |file|
    file.write(contents)
  end
end

post "/garden/add" do
  # validate input params
    # error and redirect
  
  if valid_garden_input?(params["garden_name"], params["area"])
    #success
    # generate a garden in
    user_data = load_user_file
    user_gardens = user_data["gardens"]

    garden_name = params["garden_name"]
    area = params["area"].strip.to_i
    id = generate_id(user_gardens)

    new_garden = Garden.new(garden_name, area)
    
    # switched to hash
    user_gardens[id] = new_garden

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

# edit garden properties ############# TODO waiting for forms
get "/garden/:id/edit" do
  # form with
    # name
      # prepopulate
    # area
      # prepopulate
  # also a delete button
  
  erb :edit_garden
end

# submit data to add/remove garden
post "/garden/:id/edit" do
  if validate teh inputs is true
    # edit the file
    session[:message] = "Your garden has been updated"
    redirect "/"
  else
    status 422
    session[:message] = "a validation error, probably"
    erb :edit_garden
  end
end


# delete a garden
post "/garden/:id/delete" do
end


################## 5/24 goal

def load_garden(id)
end

def add_planting_to_garden(garden, params)
  # create a new plantings obj with the params
  name = params["name"]
  harvest_date = Date.new(params["h_year"].to_i, params["h_month"].to_i, params["h_day"].to_i)
  grow_time = params["grow_time"].to_i

  new_planting = Planting.new(name, harvest_date, grow_time)
  # create a new planting ID from the garden hash
  id = generate_id(garden.plantings)
  # add kv pair of id:planting obj to the Garden obj

    # id is integer or symbol?
  garden << new_planting
end

# add a new planting to a garden
post "/garden/:id/plantings/add" do |garden_id|
  user_data = load_user_file
  garden = user_data["gardens"][garden_id.to_i]
  add_planting_to_garden(garden, params)
  # save the data
  save_to_user_file(user_data)
  # create a success msg
  session[:message] = "Added new planting to garden"
  # redirect to homepage
  redirect "/"
end

def edit_planting(planting, params)
  planting.harvest_date = Date.new(params["h_year"].to_i, params["h_month"].to_i, params["h_day"].to_i)
  planting.change_name(params["name"])
  planting.num_plants = params["num_plants"].to_i
  planting.area_per_plant = params["area_per_plant"].to_f
  planting.grow_time = params["grow_time"].to_i
end
# edit the parameters of a planting
post "garden/:id/plantings/:id/edit" do |garden_id, planting_id|
  user_data = load_user_file
  garden = user_data["gardens"][garden_id.to_i]
  planting = garden.plantings[planting_id]

  edit_planting(planting, params)
  # save the data
  save_to_user_file(user_data)
  # create a success msg
  session[:message] = "Added new planting to garden"
  # redirect to homepage
  redirect "/"
  # load the users file

  # access the specified planting

  # run the planting accessor methods to push the modifications through

  # save the file

  # confirm with message

end

# delete a planting
post "garden/:id/plantings/:id/delete" do
end