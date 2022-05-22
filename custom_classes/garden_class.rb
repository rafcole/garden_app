# does garden class need to inherit from anything? Automatically inherit from basic object?
# does it know its own name?
require 'simplecov'
SimpleCov.start

require 'Date'
require 'pry'
require 'pry-byebug'

class Garden
  attr_reader :plantings, :area, :name

  def initialize(name, area = 0)
    @name = name
    @plantings = []
    @area = area
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

  def capacity_exceeded?(time_frame)
    max_area, max_area_time = max_area_required(time_frame)
    @area < max_area
  end

  def active_period
    return nil if @plantings.empty?

    earliest_planting = @plantings.map { |planting| planting.planting_date }.min 
    latest_harvest = @plantings.map { |planting| planting.harvest_date }.max

    earliest_planting.. latest_harvest
  end

  # problem - this calculates the sum total of all square footage
  # used through out the lifespan of the garden
  # needs to calculated the max area required within a given timeframe

  # area should be a mostly static value to report the size of the garden
  
  # def area
  #   @plantings.map { |planting| planting.area_needed }.reduce(:+)
  # end

  def max_area_required(time_frame)
    # time_frame = (start_time.. end_time)
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
    active_plantings = plantings_active_in_range(time_frame)

    # filter out plantings without data on num plants and area per plant
    active_plantings.select! { |planting| planting.area_needed }


    # fallow fields? [zero square footage, no timeframe of peak activity]
    return [0, nil] if active_plantings.empty?


    
    # Create an array of dates on which we will check the area of all in season plants
    test_dates = planting_dates_in_range(time_frame, active_plantings).values

    #binding.pry
    test_dates << time_frame.min
    #   Inlude start date argument and the start dates of all in season plants which 
    #   fall between the start and end date arguments, inclusive
    area_per_date = Hash.new

    test_dates.each do |date|
      area_required = area_needed_on_date(date, active_plantings)
      area_per_date[date] = area_required
    end

    # doesn't account for multiple max area requirements of the same value
    max_area_required = area_per_date.values.max
    starting_day_of_max_area = area_per_date.key(max_area_required)
    ending_day_of_max_area = [next_harvest_date(starting_day_of_max_area, plantings), time_frame.max].min

    peak_utilization_dates = (starting_day_of_max_area.. ending_day_of_max_area)

    [max_area_required, peak_utilization_dates]

    # Create a hash with Area key and Date values
    # Return the highest KV pair as a two object array
  end


  def next_harvest_date(date, plantings = @plantings)
    # takes a starting date, searches through plantings, returns the next subsequent harvest date
    # Isolate the plantings which are active on 'date'
    # Do we want to assume that the array of plantings objects has been filtered to any degree?

    # Trip up - does plantings_active_in_range include potential newcomers?

    # Sort the plantings by their harvest date
    # Return the earliest date object harvest date (minimum val of the sorted plantings?)

    # potentially redundant
    if plantings == @plantings 
      plantings = plantings.select { |planting| date <= planting.harvest_date }
    end

    plantings.map { |planting| planting.harvest_date }.min
  end
  # sum the areas of the plants which are active on a given day
  # test stub written
  def area_needed_on_date(date, plantings_arr = @plantings)
    return 0 if (plantings_arr.nil? || plantings_arr.empty?)  
    
    #puts plantings_arr
    candidates = plantings_active_on_date(date, plantings_arr)
    return 0 if candidates.empty?

    arr_area = candidates.map { |planting| planting.area_needed }
    arr_area.reduce(:+)
  end

  # test stub written
  def planting_dates_in_range(date_range, plantings = @plantings)
    starts_in_range = plantings.select { |planting| date_range.cover?(planting.planting_date) }

    #binding.pry
    
    results = Hash.new

    starts_in_range.each { |planting| results[planting] = planting.planting_date }

    # starts_in_range.map { |planting| planting.planting_date }
    results
  end

  # test written
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

  # test written
  def plantings_active_on_date(date, plantings = @plantings)
    #puts plantings
    results = plantings.select { |planting| planting.active_on?(date) }
    #puts "line 136 == #{results.to_s}"
    results
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
    @harvest_date - ((@grow_time * 7) - 1)
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
    return nil unless @num_plants && @area_per_plant
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