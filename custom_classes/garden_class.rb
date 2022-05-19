# does garden class need to inherit from anything? Automatically inherit from basic object?
# does it know its own name?

class Garden
  attr_accessor :area

  def initialize
    @harvests = []

    # add validation here or in the app?
    @num_plants
  end

  def << (new_harvest)
    @harvests << new_harvest
  end
end

class Harvest
  attr_reader :name, :harvest_date, :num_plants, :area_per_plant

  def initialize(name)
    @name = name
  end

  def harvest_date=(time_obj)
    raise ArgumentError unless time_obj.class == Time

    @harvest_date = time_obj
  end

  def num_plants=(num)
    raise ArgumentError unless num.class == Integer

    @num_plants = num
  end

  def area_per_plant=(num)
    raise ArgumentError unless num.class == Integer

    @area_per_plant
  end

  def area_needed
    @num_plants * @area_per_plant
  end

  def grow_time=(num_weeks)
    raise ArgumentError unless num_weeks.kind_of? Numeric # TODO look up how to make this Numeric

    @grow_time = num_weeks
  end

  def planting_date
    weeks_to_seconds = (60 * 60 * 24 * 7)
    
    # should return new Time obj
    @harvest_date - (@grow_time * weeks_to_seconds)
  end
end