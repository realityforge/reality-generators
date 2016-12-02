$:.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'test/unit/assertions'
require 'reality/generators'

class Reality::TestCase < Minitest::Test
  include Test::Unit::Assertions

  def setup
    Reality::Generators::TargetManager.reset_targets
  end
end
