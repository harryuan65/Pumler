module Pumler
  def get_column_types(model)
    model.columns_hash.each_with_object({}) { |(k, v), res| res.merge!({ k => v.type }) }
  end

  def model_to_open_api_component(model)
    properties = model.columns_hash.each_with_object({}) do |(k, v), res|
      type = case v.type
             when :binary
               { "type" => "string", "format" => "binary" }
             when :datetime
               { "type" => "string", "format" => "date-time" }
             when :decimal, :float
               { "type" => "number" }
             when :primary_key
               { "type" => "string", "format" => "primary_key" }
             when :text
               { "type" => "string", "format" => "text" }
             when :time
               { "type" => "string", "format" => "timestamp" }
             when :timestamp
               { "type" => "string", "format" => "timestamp" }
             else
               { "type" => v.type.to_s }
             end
      res.merge!({ k.to_s => type })
    end
    data = {
      model.to_s => {
        "type" => "object",
        "properties" => properties
      }
    }
    data.to_yaml[4..-1]
  end
end
