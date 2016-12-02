$:.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'test/unit/assertions'
require 'reality/generators'

class Reality::TestCase < Minitest::Test
  include Test::Unit::Assertions

  def setup
    Reality::Generators::TargetManager.reset_targets
    @temp_dir = nil
  end

  def teardown
    unless @temp_dir.nil?
      FileUtils.rm_rf @temp_dir unless ENV['NO_DELETE_DIR'] == 'true'
      @temp_dir = nil
    end
  end

  def temp_dir
    if @temp_dir.nil?
      base_temp_dir = ENV['TEST_TMP_DIR'] || File.expand_path("#{File.dirname(__FILE__)}/../tmp")
      @temp_dir = "#{base_temp_dir}/generators-#{Time.now.to_i}"
      FileUtils.mkdir_p @temp_dir
    end
    @temp_dir
  end
end
