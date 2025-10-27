# frozen_string_literal: true

require_relative "../base"

module NovacloudClient
  module Objects
    module Solutions
      # Represents the payload returned when checking program over-specification.
      class OverSpecDetectionResult < Base
        attr_accessor :logid, :status
        attr_reader :items

        def initialize(attributes = {})
          @items = []
          super
        end

        def data=(value)
          @items = Array(value).map { |entry| Item.new(entry) }
        end

        alias data items

        # Entry describing over-specification findings for a specific set of players.
        class Item < Base
          attr_accessor :over_spec_type
          attr_reader :over_spec, :player_ids

          def initialize(attributes = {})
            @details = []
            super
          end

          def over_spec=(value)
            @over_spec = !!value
          end

          def over_spec?
            over_spec
          end

          def player_ids=(value)
            @player_ids = Array(value)
          end

          def over_spec_detail=(value)
            @details = Array(value).map { |detail| Detail.new(detail) }
          end

          def details
            @details ||= []
          end

          # Detail record for a widget that exceeds specifications.
          class Detail < Base
            attr_accessor :page_id, :widget_id
            attr_reader :over_spec_error_code, :recommendation

            def over_spec_error_code=(value)
              @over_spec_error_code = Array(value)
            end

            def over_spec_error_codes
              @over_spec_error_code
            end

            def recommend=(value)
              @recommendation = value ? Recommendation.new(value) : nil
            end

            # Suggested adjustments for bringing a widget within spec.
            class Recommendation < Base
              attr_accessor :width, :height, :postfix, :fps, :byte_rate, :codec
            end
          end
        end
      end
    end
  end
end
