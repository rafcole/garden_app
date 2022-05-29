# does garden class need to inherit from anything? Automatically inherit from basic object?
# does it know its own name?
require 'simplecov'
SimpleCov.start

require 'Date'
require 'pry'
require 'pry-byebug'

class Garden
  attr_reader :plantings, :area, :name, :id

  def initialize(name, area = 0)
    @name = name
    @plantings = {}
    @area = area
    #id = id collaborator object knowing its own id is hacky array work around?
  end

  # will this interfere with method definition from garden.rb?
  # def self.generate_id(hash)
  #   return 1 if hash.nil? || hash.empty?

  #   hash.keys.max + 1
  # end

  def set_id(id)
    @id = id
  end

  def << (new_planting)
    raise ArgumentError unless new_planting.class == Planting

    # repeated from garden.rb
    id = generate_id(@plantings)

    @plantings[id] = new_planting
    # old model @planting was an array
    # new model @planting[id] = planting_object
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

    earliest_planting = @plantings.values.map { |planting| planting.planting_date }.min 
    latest_harvest = @plantings.values.map { |planting| planting.harvest_date }.max

    earliest_planting.. latest_harvest
  end

  def max_area_required(time_frame)

    # Take the array of plantings, select only those in which are active between the start and end dates
    active_plantings = plantings_active_in_range(time_frame)

    # filter out plantings without data on num plants and area per plant
    active_plantings.select! { |planting| planting.area_needed }

    # fallow fields? [zero square footage, no timeframe of peak activity]
    return [0, nil] if active_plantings.empty?

    # Create an array of dates on which we will check the area of all in season plants
    test_dates = planting_dates_in_range(time_frame, active_plantings).values

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
    # Trip up - does plantings_active_in_range include potential newcomers?

    if plantings == @plantings 
      plantings = plantings.select { |_id, planting| date <= planting.harvest_date }
    end

    plantings.map { |_id, planting| planting.harvest_date }.min
  end

  def upcoming_harvests(limit, cut_off_date = Date.today + 60)
    candidates = plantings_active_in_range(Date.today.. cut_off_date)

    candidates.sort_by! { |planting| planting.harvest_date }

    candidates.first(limit)
  end

  def upcoming_plantings(limit, cut_off_date = Date.today + 60)
    candidates = plantings_active_in_range(Date.today.. cut_off_date)

    candidates.sort_by! { |planting| planting.planting_date }

    candidates.first(limit)
  end
  # sum the areas of the plants which are active on a given day
  def area_needed_on_date(date, plantings_arr = @plantings.values)
    return 0 if (plantings_arr.nil? || plantings_arr.empty?)  
    
    candidates = plantings_active_on_date(date, plantings_arr)
    return 0 if candidates.empty?

    arr_area = candidates.map { |planting| planting.area_needed }
    arr_area.reduce(:+)
  end

  def planting_dates_in_range(date_range, plantings = @plantings.values)
    starts_in_range = plantings.select { |planting| date_range.cover?(planting.planting_date) }

    results = Hash.new

    starts_in_range.each { |planting| results[planting] = planting.planting_date }

    results
  end

  def plantings_active_in_range(date_range)
    results = []
    # trim plantings which will be finished before range or won't start until after range
    candidate_plantings = @plantings.values.reject do |planting|
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

  def plantings_active_on_date(date, plantings_arr = @plantings.values)
    results = plantings_arr.select { | planting| planting.active_on?(date) }
    results
  end

  def self.valid_input?(name_str, area_str)
    return false if name_str.strip.size == 0

    area_str.strip!
    if area_str.size > 0
      return false unless area_str.to_i.to_s == area_str
    end
  
    true
  end
end

class Planting
  attr_reader :name, :harvest_date, :num_plants, :area_per_plant, :grow_time, :id

  def initialize(name, harvest_date, grow_time)
    @name = name
    @harvest_date = harvest_date
    @grow_time = grow_time
  end

  def set_id(id)
    @id = id
  end

  def active_on?(date)
    season.include? date
  end

  def change_name(new_name)
    @name = new_name
  end

  def harvest_date=(time_obj)
    raise ArgumentError unless time_obj.class == Date

    @harvest_date = time_obj
  end

  def planting_date
    # returns date obj, assume @grow_time measured in weeks
    @harvest_date - ((@grow_time * 7) - 1).truncate
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
    (planting_date.. harvest_date)
  end
end