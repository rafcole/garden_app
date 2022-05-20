# does garden class need to inherit from anything? Automatically inherit from basic object?
# does it know its own name?

require 'Date'

class Garden
  attr_reader :plantings, :area, :name

  def initialize(name, area = 0)
    @name = name
    @plantings = []
    @area
  end

  def << (new_planting)
    raise ArgumentError unless new_planting.class == Planting

    @plantings << new_planting
  end

  def change_area(new_val)
    @area = new_val
  end

  def rename(new_name)
    @name = new_name
  end

  # problem - this calculates the sum total of all square footage
  # used through out the lifespan of the garden
  # needs to calculated the max area required within a given timeframe

  # area should be a mostly static value to report the size of the garden
  
  # def area
  #   @plantings.map { |planting| planting.area_needed }.reduce(:+)
  # end

  def max_area_required(start_time, end_time)
    # Input - two Date objects which gets us to **an array of Planting objects**
    # Output - Numeric, probably integer representing the square footage required

    # We need to know the peak land usage between March and November of 2022

    # Data - An array of planting objects which are in season **including partial!**
    # between the start and the end dates



    # Gather up all the start dates for plantings
    # which are planted between the start_time and the end time
    # ** 

    #   For each start date, check the total area required by all in-season
    #   plants on that particular day
    #     Helper method area_needed_on_date

    #   The highest value is the maximum area required by that garden



    # Take the array of plantings, select only those in which are active between the start and end dates
    
    # Create an array of dates on which we will check the area of all in season plants
    #   Inlude start date argument and the start dates of all in season plants which 
    #   fall between the start and end date arguments, inclusive

    # Create a hash with Area key and Date values
    # Return the highest KV pair as a two object array


  end

  # sum the areas of the plants which are active on a given day
  def area_needed_on_date(date)
  end

  # return an array of plants active on that day
  # def plantings_active(date_or_range)
  #   if date_or_range.class == range
  #     # [planting which was already growing and will be harvested in the range,
  #     # plant which will be planted in this range but won't harvested in the range,
  #     # planting which neither starts nor ends during the range - totally irrelevant,
  #     # plant which will be planted before end of range but not harvested before end of range]
  #   else
  #     # Iterate through the plantings array
  #     @plantings.select { |planting| planting.season.include?(date) }
  #   end
  # end
  def plantings_active_in_range(date_range)
    results = []

    # trim plantings which will be finished before range or won't start until after range
    candidate_plantings = @plantings.reject do |planting|
      (date_range.min > planting.harvest_date) || (date_range.max < planting.planting_date)
    end

    date_range.each do |date|
      candidate_plantings.each do |planting| 
        results << planting if planting.active_on?(date) 
      end

      candidate_plantings.delete_if { |planting| results.include?(planting) }
    end

    results
  end

  def plantings_active_on_date(date)
    @plantings.select { |planting| planting.active_on?(date) }
  end
end

class Planting
  attr_reader :name, :harvest_date, :num_plants, :area_per_plant, :grow_time

  def initialize(name, harvest_date, grow_time)
    @name = name
    @harvest_date = harvest_date
    @grow_time = grow_time
  end

  def active_on?(date)
    season.include? date
  end

  def harvest_date=(time_obj)
    raise ArgumentError unless time_obj.class == Date

    @harvest_date = time_obj
  end

  def planting_date
    # assume @grow_time measured in weeks
    
    # should return new Date obj
    @harvest_date - (@grow_time * 7)
  end

  def num_plants=(num)
    raise ArgumentError unless num.class == Integer

    @num_plants = num
  end

  def area_per_plant=(num)
    raise ArgumentError unless num.kind_of? Numeric

    @area_per_plant = num
  end

  def area_needed
    @num_plants * @area_per_plant
  end

  def grow_time=(num_weeks)
    raise ArgumentError unless num_weeks.kind_of? Numeric

    @grow_time = num_weeks
  end

  def season
    # returns range, there's no special range type for Date objs
    (planting_date.. harvest_date)
  end
end