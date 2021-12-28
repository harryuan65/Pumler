# frozen_string_literal: true

require_relative "pumler/version"
require_relative "pumler/generator"

# ER model generator in Plantuml format for active record
module Pumler
  class Error < StandardError; end

  # Root
  class Performer
    class << self
      def pick_model_base
        Gem::Version.new(Rails.version) > Gem::Version.new("5.0.0") ? ApplicationRecord : ActiveRecord::Base
      end

      def generate!
        Generator.new(pick_model_base, {}).generate!
      end
    end
  end
end
