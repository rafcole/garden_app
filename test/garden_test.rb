ENV["RACK_ENV"] = "test"

require "fileutils"

require "minitest/autorun"
require "rack/test"

require_relative "../garden"
#require_relative "../garden_class"

class GardenTest < Minitest::Test

  include Rack::Test::Methods

  # Rack::Test::Methods expects to be able to call 'app', which returns a Rack application
  def app
    Sinatra::Application
  end

  # access the session

  # logged in user session - was admin session

  def setup
    FileUtils.mkdir_p(user_data_path)

    # need to generate session for helper methods
    get "/"
    create_all_users_file
    #generate_sample_users
  end

  def create_all_users_file
    hsh = { "admin" => { "password" => ''} }
    File.open(File.join(user_data_path + "/all_users.yaml"), "w") do |file|
      file.write(hsh.to_yaml)
    end
  end

  # def generate_sample_users
  #   file_content = {
  #                   "admin" => nil,
  #                   "bill" => {
  #                     "password" => "$2a$12$vW.uJZvB7pztOuvnsHCLeOg.wDLhgA1ayzWCGmwmJ1cV1q7OkJ5ay",
  #                     "id" => 2
  #                   }
  #   }
  #   path = user_data_path + "/all_users.yaml"
  #   file_content = file_content.to_yaml

  #   File.open(File.join(path), "w") do |file|
  #     file.write(file_content)
  #   end
  # end

  def generate_sample_users
    #binding.pry
    name = "bill"
    password = "billspassword"

    create_user(name, password)
 
    name = "sonia"
    password = "soniaspassword"

    create_user(name, password)
  end

  def test_create_user
    create_user("bob", "plzhash")

    assert_includes load_all_users_file.keys, "bob"
    bobs_id = load_all_users_file["bob"]["id"]
    user_data_dir_content = Dir.children(user_data_path)
    assert_includes user_data_dir_content, "3.yaml"# a file with bobs user ID exists
  end

  def test_user_id_continuity
    # confirm that the user id assigned at user creation correlates
    # with the user specific YAML user_data/id.yaml

    # create a user
    # create a garden object
    # add that garden object to the user
    # access the user id via user name in all_users.yaml
    # check the contents of user gardens and make sure the garden
    # in there is the same garden object created earlier
  end

  def teardown
    # delete contents of /test/users
    # not deleting all_users.yaml because it's a useful diagnostic
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { user: 'admin' }}
  end

  def sample_user_session
    { "rack.session" => { user: 'bill' }}
  end

  def test_homepage_keystones_signed_out
    #skip
    # get the homepage
    get "/"
    assert_nil session[:user]
    # make sure no one is logged in 
    assert_includes last_response.body, "Log in to start planning your garden"

    # check for sign in link
    assert_includes last_response.body, "href=/signin"
    assert_includes last_response.body, "href=/signup"

    # check for main header areas
    # Title area
    assert_includes last_response.body, "Your Gardens"
    # add garden area (should be a link, notify to log in to toggle between static message and link)
    assert_includes last_response.body, %q(href=/garden/add)
  end

  def test_sign_in_no_user
    #skip
    get "/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type='submit')
  end


  def test_log_in_valid_credentials 
    generate_sample_users  
    #skip
    post "/signin", { username: 'sonia', password: 'soniaspassword' }

    assert_equal 'sonia', session[:user]
    assert_equal "Welcome sonia", session[:message] 
    assert_equal 302, last_response.status
  end

  def test_log_in_invalid_password
    #skip
    post "/signin", { username: 'admin', password: 'wrong' }
    assert_includes last_response.body, "log in failed - generic"
    assert_nil session[:user]
    assert_equal 422, last_response.status
  end

  def test_log_in_invalid_username
    #skip
    post "/signin", { username: 'wrong', password: 'wrong' }
    assert_includes last_response.body, "log in failed - generic"
    assert_nil session[:user]
    assert_equal 422, last_response.status
  end

  def test_sign_out 
    generate_sample_users
    #skip
    get "/signout", {}, admin_session
    assert_nil session[:user]
    assert_equal "You have signed out successfully", session[:message]
    assert_equal 302, last_response.status
  end

  def test_sign_out_not_signed_in
    #skip
    get "/signout"

    assert_equal "You must be signed in to do that", session[:message]
    assert_equal 302, last_response.status
  end

  def test_add_new_garden
    generate_sample_users
    #skip
    post "/garden/add", { garden_name: "bills front yard", area:"200" }, sample_user_session
  
    assert_equal "Garden added", session[:message]
  end

  def test_add_new_planting
  end
end