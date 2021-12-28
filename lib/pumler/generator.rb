require_relative "model_info"

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

    def models_info
      @models_info ||= models.map { |model| ModelInfo.new(model, @options) }
    end

    def ermodels
      <<~DOC
        @startuml #{Rails.application.class} ER MODEL
        header #{Rails.application.class} ER MODEL
        skinparam backgroundColor #fffffe
        skinparam linetype polyline
        left to right direction
        #{models_info.map(&:generate_entity).join("")}
        #{models_info.map(&:generate_association_string).join("")}
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
