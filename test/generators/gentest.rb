#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'reality/generators'

module GenTest
  Reality::Logging.configure(GenTest, ::Logger::WARN)

  class Repository < Reality.base_element(:name => true)
  end

  class RepositoryTemplate < Reality::Generators::SingleFileOutputTemplate
    def render_to_string(context_binding)
      eval('"Repository: #{repository.name}"', context_binding)
    end
  end

  class RepositoryTemplate2 < Reality::Generators::SingleFileOutputTemplate
    def render_to_string(context_binding)
      eval('"Repository: #{repository.name} (Template2)"', context_binding)
    end
  end

  module TestTemplateSetContainer
    class << self
      include Reality::Generators::TemplateSetContainer
    end
  end

  TestTemplateSetContainer.target_manager.target(:repository)

  TestTemplateSetContainer.template_set(:test) do |t|
    RepositoryTemplate.new(t, [], :repository, 'repository.java', 'main/java/#{repository.name}.java')
  end

  TestTemplateSetContainer.template_set(:test2) do |t|
    RepositoryTemplate2.new(t, [], :repository, 'repository_t2.java', 'main/java/#{repository.name}Template2.java')
  end

  class << self
    def repositories
      repository_map.values
    end

    def repository_map
      @repository_map ||= {}
    end

    def repository(name)
      repository = Repository.new(name)
      self.repository_map[name.to_s] = repository
      yield repository if block_given?
      repository
    end

    def repository_by_name(name)
      self.repository_map[name.to_s] || (raise "No such repository #{name}")
    end

    def repository_by_name?(name)
      !!self.repository_map[name.to_s]
    end
  end

  class Runner < Reality::Generators::BaseRunner
    def default_descriptor
      'repository.rb'
    end

    def element_type_name
      'repository'
    end

    def log_container
      GenTest
    end

    def instance_container
      GenTest
    end

    def template_set_container
      TestTemplateSetContainer
    end
  end
end

GenTest::Runner.new.run
