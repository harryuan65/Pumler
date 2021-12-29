require_relative "columns"
require_relative "enums"

module Pumler
  module Builders
    # Builds a model to an Entity block in Plantuml format.
    class Entity
      def initialize(model, base, command_options = {})
        @command_options = command_options
        @model_base = base
        @model = model
        @name = model.to_s
        @instance_methods = get_defined_instance_methods
        @class_methods = get_defined_class_methods
      end

      def instance_methods_string
        return "" unless @instance_methods.any? && @command_options[:include_instance_method]

        <<~DOC
          \n----instance methods----
          #{
            @instance_methods.map do |method|
              "  +#{method}()\n"
            end.join("")
          }
        DOC
      end

      def class_methods_string
        return "" unless @class_methods.any? && @command_options[:include_class_method]

        <<~DOC
          \n----class methods----
          #{
            @class_methods.map do |method|
              " +#{method}()\n"
            end.join("")
          }
        DOC
      end

      def columns_string
        Builders::Columns.new(@model).generate_segment
      end

      def enum_entities_string
        Builders::Enums.new(@model).generate_segment
      end

      def generate_entity
        <<~DOC
          entity #{@name} {
          #{columns_string}#{class_methods_string}#{instance_methods_string}
          }
          #{enum_entities_string}
        DOC
      end

      private

      def filter_devise_methods_from(current_methods)
        return unless defined?(Devise)

        modules = [
          Devise::Models::Validatable,
          Devise::Models::Registerable,
          Devise::Models::Recoverable,
          Devise::Models::Omniauthable,
          Devise::Models::Rememberable,
          Devise::Models::DatabaseAuthenticatable,
          Devise::Models::Authenticatable
        ]
        exclude_methods = modules.each_with_object([]) do |md, arr|
          arr.concat md.instance_methods
        end
        current_methods - exclude_methods
      end

      def get_defined_instance_methods
        @model.instance_methods(false).select do |m|
          @model.instance_method(m).source_location.first.ends_with? "/#{@model.to_s.underscore}.rb"
        end
      end

      def get_defined_class_methods
        current_methods = (@model.public_methods - @model_base.public_methods)
        rule = %w[before_add after_add before_remove after_remove validate_associated_records
                  autosave_associated_records]
        enums = @model.defined_enums
        exclude_enum_keys = enums.keys.map(&:pluralize)
        exclude_enum_values = enums.values.map(&:keys).flatten
        rule.concat([exclude_enum_keys, exclude_enum_values])
        reg_rule = rule.join("|")
        exclude_rules = Regexp.new(reg_rule)
        current_methods = current_methods.reject do |m|
          m.to_s.match(exclude_rules)
        end
        current_methods = filter_devise_methods_from(current_methods) if @command_options[:exclude_devise_methods]
        current_methods
      end
    end
  end
end
