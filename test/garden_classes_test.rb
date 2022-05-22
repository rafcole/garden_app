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
    # test ^    ^        ^                   ^
    #      10   30      45 (harvest date)    0

    # no plantings in garden
    assert_equal 0, @my_garden.area_needed_on_date(Date.new(2022, 6, 1))

    # test WITH AND WITHOUT instance variable!
    beans = Planting.new('early beans', Date.new(2022, 6, 14), 3)
    beans.num_plants = 2
    beans.area_per_plant = 5
    @my_garden << beans

    assert_equal 10, @my_garden.area_needed_on_date(Date.new(2022, 6, 14))
    assert_equal 10, @my_garden.area_needed_on_date(Date.new(2022, 5, 25))

    # planting date before range, harvest during range
    berries = Planting.new('mayjune berries', Date.new(2022, 6, 28), 3)
    berries.num_plants = 5
    berries.area_per_plant = 4
    @my_garden << berries

    assert_equal 30, @my_garden.area_needed_on_date(Date.new(2022, 6, 8))

    # planting date and harvest occurs entirely during range
    prunes = Planting.new('injune prune', Date.new(2022, 7, 06), 4)
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

    # initialize a set of 
    # test with no plantings
    too_early = (Date.new(1999, 01, 01)..Date.new(1999, 12, 31))
    june = (Date.new(2022, 6, 1).. Date.new(2022, 6, 30))
    too_late = (Date.new(3000, 01, 01)..Date.new(3000, 12, 31))

    # no plantings loaded in @my_garden
    assert_equal 0, @my_garden.planting_dates_in_range(too_early).size
    assert_equal 0, @my_garden.planting_dates_in_range(june).size
    assert_equal 0, @my_garden.planting_dates_in_range(too_late).size

    # add one planting
    # check before, inrange, after
    beans = Planting.new('early beans', Date.new(2022, 6, 14), 1)
    @my_garden << beans

    assert_equal 0, @my_garden.planting_dates_in_range(too_early).size
    assert_equal 1, @my_garden.planting_dates_in_range(june).size
    assert_equal 0, @my_garden.planting_dates_in_range(too_late).size

    berries = Planting.new('mayjune berries', Date.new(2022, 6, 21), 2)
    @my_garden << berries

    assert_equal 0, @my_garden.planting_dates_in_range(too_early).size
    assert_equal 2, @my_garden.planting_dates_in_range(june).size
    assert_equal 0, @my_garden.planting_dates_in_range(too_late).size

    # planting day is in june, harvest day in july
    prunes = Planting.new('injune prune', Date.new(2022, 7, 1), 2)
    @my_garden << prunes

    assert_equal 0, @my_garden.planting_dates_in_range(too_early).size
    assert_equal 3, @my_garden.planting_dates_in_range(june).size
    assert_equal 0, @my_garden.planting_dates_in_range(too_late).size

    # irrlevant plantings don't impact testing
    prunes = Planting.new('kashi', Date.new(2022, 8, 1), 2)
    @my_garden << prunes
    assert_equal 0, @my_garden.planting_dates_in_range(too_early).size
    assert_equal 3, @my_garden.planting_dates_in_range(june).size
    assert_equal 0, @my_garden.planting_dates_in_range(too_late).size
  end

  def test_max_area_required
    june = (Date.new(2022, 6, 1).. Date.new(2022, 6, 30))

    

    # no plantings loaded
    #         |____________june____________|
    assert_equal [0, nil], @my_garden.max_area_required(june)


    # plantings with no area
    @my_garden << Planting.new('no-area beans', Date.new(2021, 12, 31), 2)
    assert_equal [0, nil], @my_garden.max_area_required(june)

    # too early - zero, nil
    #  |--|
    #         |____________june____________|
    beans = Planting.new('early beans', Date.new(2021, 12, 31), 2)
    beans.num_plants = 2
    beans.area_per_plant = 5
    @my_garden << beans
    assert_equal [0, nil], @my_garden.max_area_required(june)

    # too late - zero, nil
    #                                          |--|
    #         |____________june____________|
    beans.harvest_date = Date.new(2023, 12, 31)
    assert_equal [0, nil], @my_garden.max_area_required(june)
  

    # partial overlap, begining of range (10)
    #      |--10--|
    #         |____________june____________|
    beans.harvest_date = Date.new(2022, 6, 7)
    first_week_of_june = (Date.new(2022, 6, 1).. Date.new(2022, 6, 7))
    assert_equal [10, first_week_of_june], @my_garden.max_area_required(june)


    # partial overlap, end of range (10)
    #                                  |--10--|
    #         |____________june____________|
    beans.harvest_date = Date.new(2022, 7, 7)
    last_week_of_june = (Date.new(2022, 6, 24).. Date.new(2022, 6, 30))
    assert_equal [10, last_week_of_june], @my_garden.max_area_required(june)

    # inclusive, second and third week of june (10)
    #                |--10--|
    #         |____________june____________|
    beans.harvest_date = Date.new(2022, 6, 21)
    second_third_week_june = (Date.new(2022, 6, 8).. Date.new(2022, 6, 21))
    assert_equal [10, second_third_week_june], @my_garden.max_area_required(june)

    # testing pre adding area to the new planting
    berries = Planting.new('early beans', Date.new(2022, 6, 21), 2)
    @my_garden << berries

    assert_equal [10, second_third_week_june], @my_garden.max_area_required(june)


    

    # partial and inclusive (20)
    #      |--10--|
    #                |---20---|
    #         |____________june____________|

    beans.harvest_date = Date.new(2022, 6, 7)

    berries.num_plants = 4
    berries.area_per_plant = 5

    assert_equal [20, second_third_week_june], @my_garden.max_area_required(june)



    # partial and inclusive which overlap (30)
    #      |--10--|
    #           |---20---|
    #         |____________june____________|

    berries.grow_time = 3
    assert_equal [30, first_week_of_june], @my_garden.max_area_required(june)

    # inclusive overlaps
    #            |--10--|
    #                |---20---|
    #         |____________june____________|


    beans.harvest_date = Date.new(2022, 6, 14)
    beans.grow_time = 1
    second_week_of_june = (Date.new(2022, 6, 8).. Date.new(2022, 6, 14))

    assert_equal [30, second_week_of_june], @my_garden.max_area_required(june)


    #            |--10--|
    #                |---20---|
    #  |--------------25-------------------------|
    #         |____________june____________|

    corn = Planting.new('corn', Date.new(2022, 9, 1), 15)
    corn.num_plants = 5
    corn.area_per_plant = 5
    @my_garden << corn

    assert_equal [55, second_week_of_june], @my_garden.max_area_required(june)
    # be sure to test such that peak utilization range is day.. same day
  end

  def test_next_harvest_date
    # no plantings loaded
    assert_nil @my_garden.next_harvest_date(Date.new(2000))

    # load one planting
      # test from before
        # return harvest date of the planting
      # test after planting harvest date
        # should return nil
    
    beans = Planting.new('early beans', Date.new(2022, 6, 1), 1)
    @my_garden << beans
 
    # first successful date return, the harvest bean
    assert_equal Date.new(2022, 6, 1), @my_garden.next_harvest_date(Date.new(2000))

    berries = Planting.new('mayjune berries', Date.new(2022, 5, 20), 3)
    @my_garden << berries

    # start we're checking is within growing season of berries
    assert_equal Date.new(2022, 5, 20), @my_garden.next_harvest_date(Date.new(2022, 5, 14))

    # check a date after the harvest of of the berries but before the harvest of the beans
    assert_equal Date.new(2022, 6, 1), @my_garden.next_harvest_date(Date.new(2022, 5, 21))

    # what happens when searching for the next harvest date when the search date IS a harvest date?
    assert_equal Date.new(2022, 5, 20), @my_garden.next_harvest_date(Date.new(2022, 5, 20))

    # way too late
    assert_nil @my_garden.next_harvest_date(Date.new(2025))
  end
end

class PlantingTests < Minitest::Test
  def setup
    @foo = Planting.new('tomatoes', Date.new(2022, 5, 1), 3)
  end

  def test_season_includes_planting_date
    assert @foo.season.cover?(@foo.planting_date)
    assert_equal Date.new(2022, 4, 11), @foo.planting_date
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
    assert @foo.season.include?(Date.new(2022, 5, 1))
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

    # active on harvest date?
    assert @foo.active_on?(Date.new(2022, 5, 21))
  end
end