module Pumler
  module Builders
    # Create the columns segment of an entity
    class Columns
      def initialize(model)
        @model = model
      end

      def generate_segment
        @model.columns.reduce("") do |segment, adapter_column|
          name = adapter_column.name
          type = adapter_column.type
          segment + "  #{name}: #{type}#{name == "id" ? "\n  ---" : nil}\n"
        end
      end
    end
  end
end
