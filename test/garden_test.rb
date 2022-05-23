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
  end

  def teardown
    # delete contents of /test/users
  end

  def session
    last_request.env["rack.session"]
  end

  def test_homepage_keystones_signed_out
    # get the homepage
    get "/"
    # make sure no one is logged in 
    assert_includes last_response.body, "Log in to start planning your garden"

    # check for sign in link
    assert_includes last_response.body, "href=/signin"
    assert_includes last_response.body, "href=/signup"

    # check for main header areas
    # Title area
    assert_includes last_response.body, "Your Gardens"
    # add garden area (should be a link, notify to log in to toggle between static message and link)
    assert_includes last_response.body, %q(href=/add-garden)
  end

  def test_sign_in_no_user
    get "/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type='submit')
  end


  def test_log_in_valid_credentials    
    post "/signin", { username: 'admin', password: 'secret' }
    assert_equal "Welcome admin", session[:message] 
    assert_equal 'admin', session[:user]
    assert_equal 302, last_response.status
  end

  def test_log_in_invalid_password
    post "/signin", { username: 'admin', password: 'wrong' }
    assert_includes last_response.body, "log in failed - generic"
    assert_nil session[:user]
    assert_equal 422, last_response.status
  end

  def test_log_in_invalid_username
    post "/signin", { username: 'wrong', password: 'wrong' }
    assert_includes last_response.body, "log in failed - generic"
    assert_nil session[:user]
    assert_equal 422, last_response.status
  end



  # def test_garden_setter_methods
  #   foo = Harvest.new("brocolli")

  #   assert_raises(ArgumentError) { foo.num_plants = ("bar") }
  # end
end