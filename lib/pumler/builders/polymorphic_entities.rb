module Pumler
  module Builders
    # Generate PolymorphicEntities, should be called before building associations, in order to connected properly by associations
    class PolymorphicEntities
      def initialize(model, command_options = {})
        @model = model
        @command_options = command_options
      end

      def generate_segment
        polymorphic_reflections.map do |association_name, _reflection|
          <<~DOC
            interface #{association_name.classify} {
            }
          DOC
        end.join
      end

      private

      def polymorphic_reflections
        @model.reflections.select do |_association_name, reflection|
          reflection.options[:polymorphic]
        end
      end
    end
  end
end
