require 'pg'

class GardenDBPersistance
  # how to manage multiple classes?
  # all DB functions have to exist in this class? 
    # how to break out into smaller classes without losing the database
    # connection?

  # homepage is huge splat of data
    # query once - turn query into hash?
      # can't over think it in abstract, do many simple shitty queries

  def initialize(logger)
    @db = if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: "garden")
    end 

    @logger = logger
  end

  def query(sql, *params)
    @logger.info("#{sql}: #{params}")
    @db.exec_params(sql, params)
  end

  def user_name(user_id)
    sql = "SELECT user_name FROM users WHERE id = $1"
    query(sql, user_id.to_s).tuple(0)['user_name'] #doesn't seem right
    # DOES THIS RETURN NULL WHEN NO RESULTS?
      # Do we test up stream like this? Or just evaluating output?
  end

  def user_id_for_session(session_id)
    # Return the users.id from users where the name matches the session id
    sql = "SELECT id FROM users WHERE user_name = $1"
    
    results = query(sql, session_id)
    if results.num_tuples() > 0
      results.tuple(0)['id']
    else
      nil
    end
  end

  def generate_temp_user(session_id)
    sql = "INSERT INTO users(user_name, pw_hash, email, temp_user) VALUES($1, $2, $3, $4);"
  
    values = [session_id, session_id, session_id, 't']
  
    results = query(sql, *values) # need splat?

    user_id_for_session(session_id)

    # SQL statement to create user with name, pw and email which match the session_id
    #   Need the users.id for record just created, forget the quick way to do that.
    # Add an entry to the temp users table so we can delete the temp_users from users every 72 hrs 
    # Return the users.id number of the entry just created
  
    # Some circularity in here to be refactored
  end

  def disconnect
    @db.close
  end

  ################# GARDEN METHODS ###################
  def user_gardens(user_id)
    results = []
    search_results = garden_detail_for_user(user_id)

    search_results.each do |tuple|
      results << garden_detail_hash(tuple)
    end

    results
  end

  def garden_detail_for_user(user_id)
    sql = <<~SQL
        SELECT gardens.*, count(distinct plantings.id) AS num_plantings
        FROM gardens 
        JOIN users_gardens ON users_gardens.user_id = $1
        LEFT JOIN plantings ON plantings.garden_id = gardens.id
        GROUP BY gardens.id
        ORDER BY gardens.name ASC;
      SQL
    query(sql, user_id.to_s)
  end

  def garden_detail_hash(tuple)
    {
      id: tuple['id'],
      name: tuple['name'],
      area_sq_ft: tuple['area_sq_ft'],
      private: tuple['private'] == true,
      num_plantings: tuple['num_plantings']
    }
  end

  def gardens(garden_id)
    sql = "SELECT * FROM gardens WHERE id = $1"

    results = query(sql, garden_id)

    results = garden_details_hash(results.tuple(0))
  end

 ################### PLANTING METHODS ####################

  def plantings_from_garden(garden_id)
    sql = "SELECT * FROM plantings WHERE garden_id = $1"
    results = []
    query(sql, garden_id).each do |tuple|
      results << planting_detail_hash(tuple)
    end
    results
  end

  def harvest_date(planting_date, growing_weeks)
    # Input: Strings
    # Output: Date object

    # Convert planting date to a date object
    planting_date = planting_date
    # Get the multiplication right (flooring vs truncation) for grow weeks
    grow_days = (growing_weeks * 7).round

    planting_date + grow_days
    # Add grow time to planting date
    #   Return this date obj
  end
  
  def planting_detail_hash(tuple)
    planting_date = Date.parse(tuple['planting_date'])
    grow_time_weeks = tuple['grow_time'].to_f
    harvest_date = harvest_date(planting_date, grow_time_weeks)
    currently_growing = Date.today.between?(planting_date, harvest_date)

    {
      id: tuple['id'].to_i,
      garden_id: tuple['garden_id'].to_i,
      name: tuple['name'],
      description: tuple['description'],
      num_plants: tuple['num_plants'].to_i,
      area_per_plant_sq_ft: tuple['area_per_plant_sq_ft'].to_f,
      # string
      planting_date: planting_date,
      grow_time_weeks: grow_time_weeks,
      # Divergence from data avaliable in database
      harvest_date: harvest_date, 
      currently_growing: currently_growing
    }
  end
end