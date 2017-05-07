#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Reality #nodoc
  module Generators #nodoc
    module Rake #nodoc

      class BaseGenerateTask
        attr_accessor :description
        attr_accessor :namespace_key
        attr_accessor :filter
        attr_writer :verbose

        attr_reader :root_element_key
        attr_reader :key
        attr_reader :generator_keys
        attr_reader :target_dir

        attr_reader :task_name

        def initialize(root_element_key, key, generator_keys, target_dir, buildr_project = nil)
          @root_element_key = root_element_key
          @key = key
          @generator_keys = generator_keys
          @namespace_key = self.default_namespace_key
          @filter = nil
          @template_map = {}
          # Turn on verbose messages if buildr is turned on tracing
          @verbose = trace?
          @target_dir = target_dir
          yield self if block_given?
          define
          @templates = self.generator_container.generator.load_templates_from_template_sets(generator_keys)
          Reality::Generators::Buildr.configure_buildr_project(buildr_project, task_name, @templates, target_dir)
        end

        protected

        def default_namespace_key
          Generators.error('default_namespace_key should be implemented')
        end

        def generator_container
          Generators.error('generator_container should be implemented')
        end

        def root_element_type
          Generators.error('root_element_type should be implemented')
        end

        def log_container
          Generators.error('log_container should be implemented')
        end

        def instance_container
          Generators.error('instance_container should be implemented')
        end

        def root_elements_key
          Reality::Naming.pluralize(root_element_type)
        end

        def validate_root_element(element)
        end

        def root_element
          element = nil
          if self.root_element_key
            element = self.instance_container.send(:"#{self.root_element_key}_by_name", self.root_element_key)
            if self.instance_container.send(self.root_elements_key).size == 1
              self.log_container.warn("Task #{full_task_name} specifies a #{self.root_element_type}_key parameter but it can be be derived as there is only a single repository. The parameter should be removed.")
            end
          elsif self.root_element_key.nil?
            elements = self.instance_container.send(self.root_elements_key)
            if 1 == elements.size
              element = elements[0]
            else
              self.log_container.error("Task #{full_task_name} does not specify a #{self.root_element_type}_key parameter and it can not be derived. Candidate #{self.root_elements_key} include #{elements.collect { |r| r.name }.inspect}")
            end
          end

          validate_root_element(element)

          element
        end

        private

        def verbose?
          !!@verbose
        end

        def full_task_name
          "#{self.namespace_key}:#{self.key}"
        end

        def define
          desc self.description || "Generates the #{key} artifacts."
          namespace self.namespace_key do
            t = task self.key => ["#{self.namespace_key}:load"] do
              begin

                Reality::Logging.set_levels(verbose? ? ::Logger::DEBUG : ::Logger::WARN,
                                            self.log_container.const_get(:Logger),
                                            Reality::Generators::Logger,
                                            Reality::Facets::Logger) do
                  self.log_container.info "Generator started: Generating #{self.generator_keys.inspect}"
                  self.generator_container.generator.
                    generate(self.root_element_type, self.root_element, self.target_dir, @templates, self.filter)
                end
              rescue Reality::Generators::GeneratorError => e
                puts e.message
                if e.cause
                  puts e.cause.class.name.to_s
                  puts e.cause.backtrace.join("\n")
                end
                raise e.message
              end
            end
            @task_name = t.name
            Reality::Generators::Rake::TaskRegistry.get_aggregate_task(self.namespace_key).enhance([t.name])
          end
        end
      end

      class BaseLoadDescriptor
        attr_accessor :description
        attr_accessor :namespace_key
        attr_writer :verbose

        attr_reader :filename

        def initialize(filename)
          @filename = filename
          @namespace_key = self.default_namespace_key
          yield self if block_given?
          define
        end

        protected

        def default_namespace_key
          Generators.error('default_namespace_key should be implemented')
        end

        def log_container
          Generators.error('log_container should be implemented')
        end

        def pre_load
        end

        def post_load
        end

        private

        def verbose?
          !!@verbose
        end

        def define
          namespace self.namespace_key do
            task :preload

            task :postload

            desc self.description
            task :load => [:preload, self.filename] do
              begin
                self.pre_load
                Reality::Logging.set_levels(verbose? ? ::Logger::DEBUG : ::Logger::WARN,
                                            self.log_container.const_get(:Logger),
                                            Reality::Generators::Logger,
                                            Reality::Facets::Logger) do

                  require self.filename
                end
              rescue Exception => e
                print "An error occurred loading repository\n"
                puts $!
                puts $@
                raise e
              ensure
                self.post_load
              end
              task("#{self.namespace_key}:postload").invoke
            end
            Reality::Generators::Rake::TaskRegistry.get_aggregate_task(self.namespace_key)
          end
        end
      end

      class TaskRegistry
        class << self
          def get_aggregate_task(namespace)
            all_task = namespace_tasks[namespace.to_s]
            unless all_task
              desc "Generate all #{namespace} artifacts"
              all_task = task('all')
              namespace_tasks[namespace.to_s] = all_task
            end
            all_task
          end

          private

          def namespace_tasks
            @namespace_tasks ||= {}
          end
        end
      end
    end
  end
end
