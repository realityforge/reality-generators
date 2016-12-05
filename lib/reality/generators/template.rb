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

    # Error raised when template unable to generate
    class GeneratorError < StandardError
      attr_reader :cause

      def initialize(message, cause = nil)
        super(message)
        @cause = cause
      end
    end

    # Base class for all templates
    class Template < Reality::BaseElement
      attr_reader :template_set
      attr_reader :template_key
      attr_reader :guard
      attr_reader :helpers
      attr_reader :target
      attr_reader :facets
      attr_reader :extra_data

      def initialize(template_set, facets, target, template_key, helpers, options = {})
        Generators.error("Unexpected facets: #{facets.inspect}") unless facets.is_a?(Array) && facets.all? { |a| a.is_a?(Symbol) }
        Generators.error("Unknown target '#{target}' for template '#{template_key}'. Valid targets include: #{template_set.container.target_manager.target_keys.join(', ')}") unless template_set.container.target_manager.is_target_valid?(target)
        @template_set = template_set
        @facets = facets
        @target = target
        @template_key = template_key
        @helpers = helpers
        @guard = options[:guard]
        @name = options[:name] if options[:name]
        @extra_data = options[:extra_data] || {}
        template_set.send(:register_template, self)
      end

      def to_s
        name
      end

      def applicable?(faceted_object)
        return true if self.facets.empty?
        return false unless faceted_object.respond_to?(:facet_enabled?)
        self.facets.all? { |facet_key| faceted_object.facet_enabled?(facet_key) }
      end

      def output_path
        Generators.error('output_path unimplemented')
      end

      def generate(target_basedir, element, unprocessed_files)
        Generators.debug("Generating #{self.name} for #{self.target} #{name_for_element(element)}")
        return nil unless guard_allows?(element)

        generate!(target_basedir, element, unprocessed_files)
      end

      def name
        @name ||= "#{self.template_set.name}:#{self.template_key.gsub(/.*\/templates\/(.*)\.#{template_extension}$/, '\1')}"
      end

      protected

      def guard_allows?(element)
        return true if self.guard.nil?
        render_context = create_context(element)
        context_binding = render_context.context_binding
        eval(self.guard, context_binding, "#{self.template_key}#Guard")
      end

      def template_extension
        ''
      end

      def generate!(target_basedir, element, unprocessed_files)
        Generators.error('generate not implemented')
      end

      def name_for_element(element)
        element.respond_to?(:qualified_name) ? element.qualified_name : element.name
      end

      def create_context(value)
        context = RenderContext.new
        context.set_local_variable(self.target.to_s.gsub(/^.*\./, ''), value)
        self.extra_data.each_pair do |k, v|
          context.set_local_variable(k, v)
        end
        self.helpers.each do |helper|
          context.add_helper(helper)
        end
        context
      end
    end

    # Base class for templates that generate a single file
    class SingleFileOutputTemplate < Template
      attr_reader :output_filename_pattern

      def initialize(template_set, facets, target, template_key, output_filename_pattern, helpers = [], options = {})
        super(template_set, facets, target, template_key, helpers, options)
        @output_filename_pattern = output_filename_pattern
      end

      def output_path
        output_filename_pattern
      end

      protected

      def generate!(target_basedir, element, unprocessed_files)
        object_name = name_for_element(element)
        render_context = create_context(element)
        context_binding = render_context.context_binding
        begin
          output_filename = eval("\"#{self.output_filename_pattern}\"", context_binding, "#{self.template_key}#Filename")
          output_filename = File.join(target_basedir, output_filename)
          unprocessed_files.delete(output_filename)
          result = self.render_to_string(context_binding)
          FileUtils.mkdir_p File.dirname(output_filename) unless File.directory?(File.dirname(output_filename))
          if File.exist?(output_filename) && IO.read(output_filename) == result
            Generators.debug "Skipped generation of #{self.name} for #{self.target} #{object_name} to #{output_filename} due to no changes"
          else
            File.open(output_filename, 'w') { |f| f.write(result) }
            Generators.debug "Generated #{self.name} for #{self.target} #{object_name} to #{output_filename}"
          end
        rescue => e
          raise GeneratorError.new("Error generating #{self.name} for #{self.target} #{object_name} due to '#{e}'", e)
        end
      end

      def render_to_string(context_binding)
        Generators.error('render_to_string not implemented')
      end
    end
  end
end
