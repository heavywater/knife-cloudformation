require 'sfn'

module Sfn
  class Command
    # Cloudformation describe command
    class Describe < Command

      include Sfn::CommandModule::Base

      # information available
      unless(defined?(AVAILABLE_DISPLAYS))
        AVAILABLE_DISPLAYS = [:resources, :outputs]
      end

      # Run the stack describe action
      def execute!
        stack_name = name_args.last
        stack = provider.connection.stacks.get(stack_name)
        if(stack)
          display = [].tap do |to_display|
            AVAILABLE_DISPLAYS.each do |display_option|
              if(config[display_option])
                to_display << display_option
              end
            end
          end
          display = AVAILABLE_DISPLAYS.dup if display.empty?
          display.each do |display_method|
            self.send(display_method, stack)
            ui.info ''
          end
        else
          ui.fatal "Failed to find requested stack: #{ui.color(stack_name, :bold, :red)}"
          exit -1
        end
      end

      # Display resources
      #
      # @param stack [Miasma::Models::Orchestration::Stack]
      def resources(stack)
        stack_resources = stack.resources.all.sort do |x, y|
          y.updated <=> x.updated
        end.map do |resource|
          Smash.new(resource.attributes)
        end
        things_output(stack.name, stack_resources, :resources)
      end

      # Display outputs
      #
      # @param stack [Miasma::Models::Orchestration::Stack]
      def outputs(stack)
        ui.info "Outputs for stack: #{ui.color(stack.name, :bold)}"
        unless(stack.outputs.empty?)
          stack.outputs.each do |output|
            key, value = output.key, output.value
            key = snake(key).to_s.split('_').map(&:capitalize).join(' ')
            ui.info ['  ', ui.color("#{key}:", :bold), value].join(' ')
          end
        else
          ui.info "  #{ui.color('No outputs found')}"
        end
      end

      # @return [Array<String>] default attributes
      def default_attributes
        %w(updated logical_id type status status_reason)
      end

    end
  end
end