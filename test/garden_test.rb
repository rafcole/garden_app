ENV["RACK_ENV"] = "test"

require "fileutils"

require "minitest/autorun"
require "rack/test"

require_relative "../garden"

class GardenTest < Minitest::Test

  include Rack::Test::Methods

  # Rack::Test::Methods expects to be able to call 'app', which returns a Rack application
  def app
    Sinatra::Application
  end

  # access the session

  # logged in user session - was admin session

  def setup
  end

  def teardown
    # delete contents of /test/users
  end

  def test_homepage_keystones_signed_out
    # get the homepage
    get "/"
    # make sure no one is logged in 
    assert_includes last_response.body, "Log in to start planning your garden"

    # check for sign in link
    assert_includes last_response.body, "href=/signin"
    assert_includes last_response.body, "href=/signup"

    # check for sign up link

    # check for main header areas
      # Title area
      assert_includes last_response.body, "<h1>Your garden</h1>"

      # add garden area (should be a link, notify to log in to toggle between static message and link)
      assert_includes last_response.body, "Log in to add a gardening area"
      # Garden areas as separate H1s?
        # loren impsum examples?
      # Summary at the bottom
      assert_includes last_response.body, "See all of your garden needs"
      # is this yield_content?
    
  end
end