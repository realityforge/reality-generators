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

    module Generator
      class << self

        # Return a list of templates loaded from specified template_set_keys
        def load_templates_from_template_sets(template_set_container, template_set_keys)
          template_map = {}
          load_templates(template_set_container, template_map, template_set_keys, [])
          template_map.values
        end

        # Actually perform the generation of files from specified templates.
        # Files are generated to the specified target directory. Any files that
        # are not generated by this process are deleted. The files generated are
        # based on the specified templates.
        # The traversal starts from a root element of specified element_type and
        # traverses all elements that are contained transitively by the root element.
        # The templates then generate files from traversed elements.
        def generate(template_set_container, element_type, element, directory, templates, filter)
          unprocessed_files = (Dir["#{directory}/**/*.*"] + Dir["#{directory}/**/*"]).uniq

          Generators.debug "Templates to process: #{templates.collect { |t| t.name }.inspect}"

          targets = {}
          collect_generation_targets(template_set_container, element_type, element, element, targets)

          templates.each do |template|
            Generators.debug "Evaluating template: #{template.name}"
            elements = targets[template.target]

            elements.each do |element_pair|
              element = element_pair[1]
              if template.applicable?(element_pair[0]) && (filter.nil? || filter.call(template.target, element))
                template.generate(directory, element, unprocessed_files)
              end
            end if elements
          end

          unprocessed_files.sort.reverse.each do |file|
            if File.directory?(file)
              if (Dir.entries(file) - %w(. ..)).empty?
                Generators.debug "Removing #{file} as no longer generated"
                FileUtils.rmdir file
              end
            else
              Generators.debug "Removing #{file} as no longer generated"
              FileUtils.rm_f file
            end
          end

          Generators.info 'Generator completed'
        end

        private

        def load_templates(template_set_container, template_map, template_set_keys, processed_template_sets)
          template_set_keys.each do |template_set_key|
            next if processed_template_sets.include?(template_set_key)
            template_set = template_set_container.template_set_by_name(template_set_key)
            processed_template_sets << template_set_key
            load_templates(template_set_container, template_map, template_set.required_template_sets, processed_template_sets)
            template_set.templates.each do |template|
              template_map[template.name] = template
            end
          end
        end

        # Collect all generation targets. This is a map of type to an array of element pairs of that type.
        # The element pair includes two elements, the "parent" standard element that is facet as per normal
        # and the actual element that is used for generation. The first element is used when checking if
        # element is applicable? to be generated while the second is basis of generation.
        # i.e.
        #
        # {
        #   :repository => [ [repository, repository] ],
        #   :data_module => [ [module1, module1], [module2, module2]],
        #   :entity => [[entity1, entity1], [entity2, entity2]],
        #   :'keycloak.client' => [[repository, client]],
        #   ...
        # }
        #
        def collect_generation_targets(template_set_container, element_type, scope_element, element, targets)
          (targets[element_type] ||= []) << [scope_element, element]

          template_set_container.target_manager.targets_by_container(element_type).each do |target|
            subelements = nil
            subscope = nil
            if target.standard?
              subelements = element.send(target.access_method)
            elsif element.facet_enabled?(target.facet_key)
              subelements = element.send(target.facet_key).send(target.access_method)
              subscope = element
            end

            next unless subelements
            subelements = [subelements] unless subelements.is_a?(Array)

            subelements.each do |subelement|
              collect_generation_targets(template_set_container, target.qualified_key, subscope || subelement, subelement, targets)
            end
          end
        end
      end
    end
  end
end
