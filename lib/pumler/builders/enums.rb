module Pumler
  module Builders
    # Generate defined enums as enum block
    class Enums
      def initialize(model)
        @model = model
      end

      def generate_segment
        model_name = @model.to_s
        enums = @model.defined_enums
        return "" if enums.empty?

        enums.map do |enum_key, enum_values|
          <<~DOC
            enum #{model_name}.#{enum_key} {
            #{enum_values.map { |k, v| "  #{k}: #{v}" }.join("\n")}
            }
            #{model_name}.#{enum_key}-->#{model_name}
          DOC
        end.join("")
      end
    end
  end
end
