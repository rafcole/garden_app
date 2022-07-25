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
    # Want this to return an array of hashes
    # [{id:, name:, area_sq_ft:, private:}]
    # Eventaully we can iterate throught the hashes, no problem

    # Declare a results array
    # Write out the SQL for all gardens of a user
    # Run the query, store it in a variable
    # Iterate over the query tuples
    #   Add formatted hash from current tuple to results array
    # Return results
    results = []
    sql = <<~SQL
      SELECT gardens.id, gardens.name, gardens.area_sq_ft, gardens.private 
      FROM gardens LEFT JOIN users_gardens ON users_gardens.user_id = $1
      GROUP BY gardens.id
      ORDER BY gardens.name ASC
      SQL
    search_results = query(sql, user_id.to_s)

    search_results.each do |tuple|
      results << {
                    id: tuple['id'],
                    name: tuple['name'],
                    area_sq_ft: tuple['area_sq_ft'],
                    private: tuple['private'] == true
                  }
    end

    results
  end
end