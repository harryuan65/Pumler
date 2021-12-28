module Pumler
  class ModelInfo
    attr_reader :command_options, :model_base, :model, :name, :columns, :instance_methods, :class_methods, :associations,
                :enums

    def initialize(model, command_options = {})
      @command_options = command_options
      @model_base = model_base
      @model = model
      @name = model.to_s
      @columns = get_columns
      @instance_methods = get_defined_instance_methods
      @class_methods = get_defined_class_methods
      @associations = get_associations
      @enums = model.defined_enums
    end

    def columns_string
      @columns.map do |key, value|
        "  #{key}: #{value}#{key == "id" ? "\n  ---" : nil}"
      end.join("\n")
    end

    def enum_entities_string
      return "" if @enums.empty?

      @enums.map do |enum_key, enum_values|
        <<~DOC
          enum #{@name}.#{enum_key} {
          #{enum_values.map { |k, v| "  #{k}: #{v}" }.join("\n")}
          }
          #{@name}.#{enum_key}-->#{@name}
        DOC
      end.join("")
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

    def generate_association_string
      return "" if @associations.empty?

      @associations.each_with_object([]) do |(association_name, relation), array|
        options = relation[:options]

        relate_type = options[:class_name] || association_name.singularize.classify
        relate_type = "\"#{relate_type}(polymorphic)\"" if options[:polymorphic]
        macro = if options[:via_scope]
                  "scope"
                elsif options[:through]
                  "#{relation[:macro]}\\n through #{options[:through]}.#{options[:source]}_id"
                else
                  relation[:macro]
                end

        case relation[:macro]
        when :has_many, :has_one
          if @command_options[:link_associations_with_foreign_key]
            array.push "#{@name}--->#{relate_type}::#{relation[:foreign_key]}: #{macro} >\n"
          else
            array.push "#{@name}--->#{relate_type}: #{macro} (#{relation[:foreign_key]}) >\n"
          end
        when :belongs_to
          if @command_options[:link_associations_with_foreign_key]
            array.push "#{@name}::#{relation[:foreign_key]}--->#{relate_type}: #{macro} >\n"
          else
            array.push "#{@name}--->#{relate_type}: #{macro} (#{relation[:foreign_key]})>\n"
          end
        end
      end
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

    def get_columns
      @model.columns_hash.reduce({}) do |res, (k, v)|
        res.merge!({
                     k => v.type
                   })
      end
    end

    def get_associations
      @model.reflections.reduce({}) do |res, (table_name, reflection)|
        options = reflection.options
        table_name = if options[:through] && options[:source_type]
                       options[:source_type]
                     else
                       table_name
                     end
        association = {
          table_name => {
            foreign_key: reflection.foreign_key,
            macro: reflection.macro,
            options: reflection.scope.present? ? options.merge({ via_scope: true }) : options
          }
        }
        pp association if table_name == "users"
        res.merge!(association)
      end
    end

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
      rule = %w[before_add after_add before_remove after_remove validate_associated_records autosave_associated_records]
      @enums = @model.defined_enums
      exclude_enum_keys = @enums.keys.map(&:pluralize)
      exclude_enum_values = @enums.values.map(&:keys).flatten
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
