require_relative '../custom_classes/garden_class'

require "minitest/autorun"

class GardenClassTests < Minitest::Test
  def setup
    @my_garden = Garden.new('backyard')
  end

  def test_initialize
    foo = Garden.new('backyard')

    assert_equal 'backyard', foo.name
    assert_empty foo.plantings
  end

  def test_add_planting
    foo = Garden.new('backyard')
    bar = Planting.new('tomatoes', Date.new(2022, 05, 01), 3)

    assert_raises(ArgumentError) { foo << 'not a planting obj' }

    foo << bar

    assert_equal [bar], foo.plantings
  end

  def test_plantings_active_in_range
    # decide on an easy to read date range
      # month of june
    june = (Date.new(2022, 6, 1).. Date.new(2022, 6, 30))

    # add the following plantings to @my_garden
    # season complete before range
    @my_garden << Planting.new('early beans', Date.new(2021, 12, 31), 2)
    # planting date before range, harvest during range
    @my_garden << Planting.new('mayjune berries', Date.new(2022, 6, 7), 3)
    # planting date and harvest occurs entirely during range
    @my_garden << Planting.new('injune prune', Date.new(2022, 6, 21), 1)
    # starts during range but harvested
    @my_garden << Planting.new('june start peppers', Date.new(2022, 7, 7), 2)
    # planting date after range
    @my_garden << Planting.new('fall beans', Date.new(2022, 10, 1), 3)
    
    # test plantings_active_in_range, looking for 3/5 of the above plantings
    assert_equal 3, @my_garden.plantings_active_in_range(june).size
  end

  def test_plantings_active_on_date
        # add the following plantings to @my_garden
    # season complete before range
    @my_garden << Planting.new('early beans', Date.new(2021, 12, 31), 2)
    # planting date before range, harvest during range
    @my_garden << Planting.new('mayjune berries', Date.new(2022, 6, 16), 3)
    # planting date and harvest occurs entirely during range
    @my_garden << Planting.new('injune prune', Date.new(2022, 6, 21), 1)
    # starts during range but harvested
    @my_garden << Planting.new('june start peppers', Date.new(2022, 7, 7), 2)
    # planting date after range
    @my_garden << Planting.new('fall beans', Date.new(2022, 10, 1), 3)
    
    date = Date.new(2022, 6, 15)

    assert_equal 2, @my_garden.plantings_active_on_date(date).size


    # Needs tests for non-instance variable value for plantings?
  end

  def test_area_needed_on_date
    # make three fully fledged planting objects
    # with partially overlapping seasons and the following space reqs

    # beans
    # |---- 10 sq ft-----|
    # berries
    #         |--- 20 sq ft --|
    # Prunes
    #              |--- 15 sq ft---|
    # test ^    ^     ^               ^
    #      10   30    45              0

    # no plantings in garden
    assert_equal 0, @my_garden.area_needed_on_date(Date.new(2022, 6, 1))

    # test WITH AND WITHOUT instance variable!
    beans = Planting.new('early beans', Date.new(2022, 6, 14), 2)
    beans.num_plants = 2
    beans.area_per_plant = 5
    @my_garden << beans

    assert_equal 10, @my_garden.area_needed_on_date(Date.new(2022, 6, 1))

    # planting date before range, harvest during range
    berries = Planting.new('mayjune berries', Date.new(2022, 6, 21), 2)
    berries.num_plants = 5
    berries.area_per_plant = 4
    @my_garden << berries

    assert_equal 30, @my_garden.area_needed_on_date(Date.new(2022, 6, 8))

    # planting date and harvest occurs entirely during range
    prunes = Planting.new('injune prune', Date.new(2022, 6, 28), 2)
    prunes.num_plants = 3
    prunes.area_per_plant = 5
    @my_garden << prunes

    assert_equal 45, @my_garden.area_needed_on_date(Date.new(2022, 6, 14))

    # after all harvest dates
    assert_equal 0, @my_garden.area_needed_on_date(Date.new(2022, 12, 31))
  end

  def test_planting_dates_in_range
    # looking for an array of date objects
    # should only include dates which fall in the date_range argument
  end
end

class PlantingTests < Minitest::Test
  def setup
    @foo = Planting.new('tomatoes', Date.new(2022, 5, 1), 3)
  end

  def test_harvest_date_arg
    assert_raises(ArgumentError) { @foo.harvest_date = 'not a TimeObj' }
  end

  def test_area_per_plant_arg
    assert_raises(ArgumentError) { @foo.area_per_plant = 'not a Numeric' }
  end

  def test_calculate_area_needed
    @foo.num_plants = 5
    @foo.area_per_plant = 2

    assert_equal 10, @foo.area_needed
  end

  def test_season
    @foo.grow_time = 3 # weeks
    @foo.harvest_date = (Date.new(2022, 5, 21))

    # assert_include wasn't working 
    assert @foo.season.include?(Date.new(2022, 5, 14))
    refute @foo.season.include?(Date.new(2022, 12, 31))

    # planting and harvest day inclusive?
    assert @foo.season.include?(Date.new(2022, 5, 21))
    assert @foo.season.include?(Date.new(2022, 4, 30))
  end

  def test_grow_time_arithmetic
    @foo.grow_time = 3
    @foo.grow_time -= 1

    assert_equal 2, @foo.grow_time
  end

  def test_active_on?
    @foo.grow_time = 3 # weeks
    @foo.harvest_date = (Date.new(2022, 5, 21))

    assert @foo.active_on?(Date.new(2022, 5, 14))
    refute @foo.active_on?(Date.new(2022, 6, 01))
  end
end