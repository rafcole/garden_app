ENV["RACK_ENV"] = "test"

require 'simplecov'
SimpleCov.start

require "fileutils"

require "minitest/autorun"
require "rack/test"

require_relative "../garden"

class GardenAppTest < Minitest::Test

  include Rack::Test::Methods

  # Rack::Test::Methods expects to be able to call 'app', which returns a Rack application
  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(user_data_path)

    # need to generate session for helper methods
    get "/"
    create_all_users_file
    #generate_sample_users
  end

  def teardown
    # delete contents of /test/users
    # not deleting all_users.yaml because it's a useful diagnostic

    clear_user_data_dir
  end

  def clear_user_data_dir
    Dir.each_child("./test/user_data") do |dir_content|
      File.delete("./test/user_data/" + dir_content) unless (dir_content == "sessions" || dir_content == "all_users.yaml")
    end
  end

  def create_all_users_file
    hsh = { "admin" => { "password" => ''} }
    File.open(File.join(user_data_path + "/all_users.yaml"), "w") do |file|
      file.write(hsh.to_yaml)
    end
  end

  def generate_sample_users
    hsh = {
            "bill" => {
                        "password" => "$2a$12$V/nDenXQ0XOo0q5zch1yv.xVk4ifOrC6HefWog5fEEXEb0M.80Zju",
                        "id" => "1"
                       },
            "sonia" => {
                        "password" => "$2a$12$wvMhlRbWyeH2tbn9/UCzgeclBmPkPsaYMZgMR2ueStrLcQjcErqNO",
                        "id" => "2"
                        }
           }
    
    hsh.each do |_user_name, data|
      create_user_file(data["id"], user_file_content_template)
    end

    File.open(user_data_path + "/all_users.yaml", "w") do |file|
      file.write(hsh.to_yaml)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { user: 'admin' }}
  end

  ############ bill is our test user workhorse

  # log bill in
  def sample_user_session
    { "rack.session" => { user: 'bill' }}
  end

  def summon_bill_and_his_front_yard_broccoli
    generate_sample_users

    # log in as bill
    post "/garden/add", { garden_name: "bills front yard", area:"100" }, sample_user_session

    params_for_plantings = { name: "broccoli",
                             h_year: "2022", 
                             h_month: "6", 
                             h_day: "30", 
                             grow_time: "3"
                            }
    post "/garden/1/plantings/add", params_for_plantings, sample_user_session
  end

  ################## Tests #####################

  def test_create_user
    generate_sample_users
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

  def test_sign_in_already_signed_in
    get "/signin", {}, admin_session

    assert_equal "You are currently signed in as admin. <a href=/signout> Click here to signout</a>", session[:message]
  end

  def test_sign_up_valid_input
    form_input = { username: "VeryValid", password: "Match11!!!", confirm_password: "Match11!!!" }
    post "/signup", form_input

    assert_equal session[:message], "Signup successful, welcome VeryValid"
  end

  def test_sign_up_existing_username
    generate_sample_users
    form_input = { username: "bill", password: "Match1!!!", confirm_password: "Match1!!!" }
    post "/signup", form_input

    assert_includes last_response.body, "The requested username is unavaliable"
  end

  def test_sign_up_invalid_username
    form_input = { username: "Not      Valid", password: "Match1!!!", confirm_password: "Match1!!!" }
    post "/signup", form_input

    assert_includes last_response.body, "The entered username is not valid"
  end

  def test_sign_up_password_invalid
    form_input = { username: "Valid", password: "not_valid", confirm_password: "not_valid" }
    post "/signup", form_input

    assert_includes last_response.body, "The entered password does not meet the password requirements"
  end

  def test_sign_up_password_not_matching
    form_input = { username: "Valid", password: "Match1!!!", confirm_password: "not_matching" }
    post "/signup", form_input

    assert_includes last_response.body, "The entered password and confirmation passwords do not match"
  end

  def test_log_in_valid_credentials 
    generate_sample_users  
    #skip
   # binding.pry
    post "/signin", username: 'sonia', password: 'soniaspassword'

    assert_equal 'sonia', session[:user]
    assert_equal "Welcome sonia", session[:message] 
    assert_equal 302, last_response.status

    create_user("richard", "madp8nter")
    post "/signin", username: "richard", password: "madp8nter"

    assert_equal 'richard', session[:user]
  end

  def test_log_in_invalid_password
    #skip
    post "/signin", { username: 'sonia', password: 'wrong' }
    assert_includes last_response.body, "log in failed - generic"
    assert_nil session[:user]
    assert_equal 422, last_response.status
  end

  def test_log_in_invalid_username
    generate_sample_users
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
  
    bills_data = load_user_file

    assert_equal Garden, bills_data["gardens"][1].class
    assert_equal "bills front yard", bills_data["gardens"][1].name

    assert_equal "Garden added", session[:message]
  end
  
  def test_add_new_garden_invalid_input
    generate_sample_users
    #skip
    post "/garden/add", { garden_name: "bills front yard", area:"4ever" }, sample_user_session
  
    assert_includes last_response.body, "Invalid input"
  end

  def test_add_new_planting
    summon_bill_and_his_front_yard_broccoli

    bills_data = load_user_file

    assert_equal "Added new planting to garden", session[:message]
    assert_equal 1, bills_data["gardens"][1].plantings.size
    assert_equal "broccoli", bills_data["gardens"][1].plantings[1].name
    # add a planting
                            
    # double check that bill's file has a planting

  end

  def test_planting_edit
    # create a planting
    summon_bill_and_his_front_yard_broccoli

    new_planting_specs = { name: "apples",
                            h_year: "2022", 
                            h_month: "7", 
                            h_day: "4", 
                            grow_time: "10"
                            # area per plant
                            # number of plants
                          }
    # edit the planting
    # here we're hardcoding the planting ID
    post "/garden/1/plantings/1/edit", new_planting_specs, sample_user_session
   
    bills_data = load_user_file
    bills_broccoli = bills_data["gardens"][1].plantings[1]
    # check the planting
    assert_equal session[:message], "The planting has been edited"
    assert bills_broccoli.class == Planting
    assert_equal "apples", bills_broccoli.name
    assert_equal Date.new(2022, 7, 4), bills_broccoli.harvest_date
    assert_equal 10, bills_broccoli.grow_time   
  end

  def test_garden_edit
    summon_bill_and_his_front_yard_broccoli

    new_garden_specs = { name: "window sill",
                         area: "321"
                        }

    post "/garden/1/edit", new_garden_specs, sample_user_session
    
    bills_data = load_user_file

    assert_equal bills_data["gardens"][1].name, "window sill"
    assert_equal bills_data["gardens"][1].area, 321

    assert_equal session[:message], "Your garden has been updated"
  end

  def test_garden_edit_invalid_input
  end

  def test_planting_delete
    summon_bill_and_his_front_yard_broccoli

    post "/garden/1/plantings/1/delete", sample_user_session

    bills_data = load_user_file
    assert_empty bills_data["gardens"][1].plantings
    assert_equal session[:message], "The planting has been deleted"
  end

  def test_garden_delete
    summon_bill_and_his_front_yard_broccoli

    # add another garden, just to check
    bills_data = load_user_file
    new_garden = { "garden_name" => "mint", "area" => "300" }
    add_garden(bills_data, new_garden)

    post "/garden/1/delete", sample_user_session

    bills_data = load_user_file
    assert_equal 1, bills_data["gardens"].size
    assert_equal session[:message], "The garden has been deleted"
  end
end

class GardenHelperTest < Minitest::Test
  def test_generate_id
    fake_user_hash = { 1 => 'user1',
                       2 => 'user2',
                       3 => 'user3'
                      }
    
    assert_equal 4, generate_id(fake_user_hash)
    
  end
end