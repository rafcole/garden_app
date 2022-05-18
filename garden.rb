require "yaml"

require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "bcrypt"

# session needs in app?
configure do
  enable :sessions
  set :session_secret, 'super secret'
end

# users route
def user_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users", __FILE__)
  else
    File.expand_path("../users", __FILE__)
  end
end

# test route

# homepage
get "/" do
  erb :home
end

# sign in
get "/signin" do 
  erb :signin
end

# sign in post
post "/signin" do
  redirect "/"
end

# sign up
get "/signup" do
  erb :signup
end

# submit sign up
post "/signup" do
  redirect "/"
end

post "/addgarden" do
  redirect "/"
end

