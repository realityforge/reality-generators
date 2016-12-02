require File.expand_path('../../helper', __FILE__)

class Reality::Generators::TestTargetManager < Reality::TestCase

  def test_target
    target1 = Reality::Generators::Target.new(:repository, nil, {})

    assert_equal :repository, target1.qualified_key
    assert_equal :repository, target1.key
    assert_equal nil, target1.container_key
    assert_equal 'repositories', target1.access_method
    assert_equal nil, target1.facet_key
    assert_equal true, target1.standard?

    target2 = Reality::Generators::Target.new(:data_module, :repository, {})

    assert_equal :data_module, target2.qualified_key
    assert_equal :data_module, target2.key
    assert_equal :repository, target2.container_key
    assert_equal 'data_modules', target2.access_method
    assert_equal nil, target2.facet_key
    assert_equal true, target2.standard?

    target3 = Reality::Generators::Target.new(:entrypoint, :repository, :facet_key => :gwt)

    assert_equal :'gwt.entrypoint', target3.qualified_key
    assert_equal :entrypoint, target3.key
    assert_equal :repository, target3.container_key
    assert_equal 'entrypoints', target3.access_method
    assert_equal :gwt, target3.facet_key
    assert_equal false, target3.standard?

    target4 = Reality::Generators::Target.new(:persistence_unit, :repository, :facet_key => :jpa, :access_method => 'standard_persistence_units')

    assert_equal :'jpa.persistence_unit', target4.qualified_key
    assert_equal :persistence_unit, target4.key
    assert_equal :repository, target4.container_key
    assert_equal 'standard_persistence_units', target4.access_method
    assert_equal :jpa, target4.facet_key
    assert_equal false, target4.standard?

    target1 = Reality::Generators::Target.new(:project, nil, :access_method => 'project_set')

    assert_equal :project, target1.qualified_key
    assert_equal :project, target1.key
    assert_equal nil, target1.container_key
    assert_equal 'project_set', target1.access_method
    assert_equal nil, target1.facet_key
    assert_equal true, target1.standard?

    assert_raise_message('Attempting to redefine target project') { Reality::Generators::Target.new(:project, nil, {}) }

    assert_raise_message("Target 'foo' defines container as 'bar' but no such target exists.") { Reality::Generators::Target.new(:foo, :bar, {}) }
  end

  def test_target_manager_basic_operation

    assert_equal false, Reality::Generators::TargetManager.is_target_valid?(:project)
    assert_equal [], Reality::Generators::TargetManager.target_keys
    assert_equal false, Reality::Generators::TargetManager.target_by_key?(:project)

    Reality::Generators::TargetManager.target(:project)

    assert_equal true, Reality::Generators::TargetManager.is_target_valid?(:project)
    assert_equal [:project], Reality::Generators::TargetManager.target_keys
    assert_equal true, Reality::Generators::TargetManager.target_by_key?(:project)
    assert_equal 1, Reality::Generators::TargetManager.targets.size
    assert_equal :project, Reality::Generators::TargetManager.targets[0].key

    Reality::Generators::TargetManager.target(:component, :project, :facet_key => :jsc, :access_method => 'comps')

    assert_equal true, Reality::Generators::TargetManager.is_target_valid?(:'jsc.component')
    assert_equal true, Reality::Generators::TargetManager.target_by_key?(:'jsc.component')
    assert_equal 2, Reality::Generators::TargetManager.targets.size
    target = Reality::Generators::TargetManager.target_by_key(:'jsc.component')
    assert_equal :component, target.key
    assert_equal :project, target.container_key
    assert_equal :jsc, target.facet_key
    assert_equal 'comps', target.access_method

    assert_equal 1, Reality::Generators::TargetManager.targets_by_container(:project).size
    assert_equal :component, Reality::Generators::TargetManager.targets_by_container(:project)[0].key

    assert_raise_message("Can not find target with key 'foo'") { Reality::Generators::TargetManager.target_by_key(:foo) }
  end
end
