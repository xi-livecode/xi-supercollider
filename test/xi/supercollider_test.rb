require 'test_helper'

class Xi::SupercolliderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Xi::Supercollider::VERSION
  end
end
