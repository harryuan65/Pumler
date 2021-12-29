require_relative "builders/entity"
require_relative "builders/polymorphic_entities"
require_relative "builders/associations"

module Pumler
  # Generates puml file base on provided target model base (ApplicationRecord or ActiveRecord::Base)
  # Maps all the models into ModelInfo, which contains all the information of the model.
  class Generator
    def initialize(target_model_base, options = {})
      @options = options
      @model_base = target_model_base
    end

    def models
      @models ||= @model_base.descendants
    end

    def entities
      @entities ||= models.map { |model| Builders::Entity.new(model, @model_base, @options) }
    end

    def polymorphic_entities
      @polymorphic_entities ||= models.map { |model| Builders::PolymorphicEntities.new(model) }
    end

    def associations_string
      models.map { |model| Builders::Associations.new(model).generate_segment }.join
    end

    def ermodels
      <<~DOC
        @startuml #{Rails.application.class} ER MODEL
        header #{Rails.application.class} ER MODEL
        skinparam backgroundColor #fffffe
        skinparam linetype polyline
        left to right direction

        #{polymorphic_entities.map(&:generate_segment).join}
        #{entities.map(&:generate_entity).join}
        #{associations_string}
        @enduml
      DOC
    end

    def generate!
      Rails.application.eager_load!
      File.open("models.puml", "w") do |file|
        file.write(ermodels)
      end
    end
  end
end
