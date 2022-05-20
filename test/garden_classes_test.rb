require_relative '../custom_classes/garden_class'

require "minitest/autorun"

class GardenClassTests < Minitest::Test
  def test_initialize
    foo = Garden.new('backyard')

    assert_equal 'backyard', foo.name
    assert_empty foo.plantings
  end

  def test_add_planting
    foo = Garden.new('backyard')
    bar = Planting.new('tomatoes')

    assert_raises(ArgumentError) { foo << 'not a planting obj' }

    foo << bar

    assert_equal [bar], foo.plantings
  end



end

class PlantingTests < Minitest::Test
  def setup
    @foo = Planting.new('tomatoes')
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
end