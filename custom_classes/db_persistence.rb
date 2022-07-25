require 'pg'

class GardenDBPersistance
  # how to manage multiple classes?
  # all DB functions have to exist in this class? 
    # how to break out into smaller classes without losing the database
    # connection?
    
  def initialize(logger)
    @db = if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: "garden")
    end 

    @logger = logger
  end

  def disconnect
    @db.close
  end
end