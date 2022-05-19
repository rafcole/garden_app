require_relative '../custom_classes/garden_class'

require "minitest/autorun"

class GardenClassTests < Minitest::Test

  def test_file_structure
    foo = Harvest.new("cabbage")

    assert_equal Harvest, foo.class
  end

end