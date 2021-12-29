module Pumler
  module Builders
    # Build associations strings for a single model. This must be done after all entities are generated else puml cannot find the entity.
    class Associations
      def initialize(model, command_options = {})
        @model = model
        @name = model.to_s

        @command_options = command_options
      end

      def generate_segment
        organize_associations(@model).each_with_object([]) do |(association_name, relationship), array|
          options = relationship[:options]
          association_name = pick_association_name(association_name, options)
          association = build_association(association_name.classify, relationship)
          array << association if association
        end.join
      end

      private

      def show_scoped?
        @command_options[:show_scoped]
      end

      def organize_associations(model)
        model.reflections.each_with_object({}) do |(table_name, reflection), hash|
          next if reflection.scope && !show_scoped?

          table_name = reflection.options[:source_type] if reflection.options[:through]

          hash[table_name] = {
            foreign_key: reflection.foreign_key,
            macro: reflection.macro,
            options: reflection.options,
            via_scope: reflection.scope.present?
          }
        end
      end

      # Use polymorphism association name first,
      # or use your defined class_name in an association.
      def pick_association_name(association_name, options)
        class_name, polymorphic = options.values_at(:class_name, :polymorphic)

        association_name = class_name || association_name.singularize.classify unless polymorphic
        association_name
      end

      # @param [Hash] relationship: the relationship info hash from #organize_associations
      def build_macro(relationship)
        options = relationship[:options]
        if relationship[:via_scope]
          "scope"
        elsif options[:through]
          "#{relationship[:macro]}\\n through #{options[:through]}.#{options[:source]}_id"
        else
          relationship[:macro]
        end
      end

      def build_association(association_name, relationship)
        macro = build_macro(relationship)
        foreign_key = relationship[:foreign_key]

        case relationship[:macro]
        when :has_many, :has_one
          # "#{@name}--->#{association_name}::#{foreign_key}: #{macro} \n"
          "#{@name}--->#{association_name}: #{macro} (#{foreign_key}) \n"
        when :belongs_to
          # "#{@name}::#{foreign_key}--->#{association_name}: #{macro} \n"
          "#{@name}--->#{association_name}: #{macro} (#{foreign_key})>\n"
        end
      end
    end
  end
end
