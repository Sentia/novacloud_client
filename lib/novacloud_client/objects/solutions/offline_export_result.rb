# frozen_string_literal: true

require_relative "../base"

module NovacloudClient
  module Objects
    module Solutions
      # Represents the payload returned from the offline export endpoint.
      class OfflineExportResult < Base
        attr_reader :display_solutions, :play_relations, :play_solutions,
                    :playlists, :schedule_constraints, :plan_json

        def display_solutions=(value)
          @display_solutions = build_artifact(value)
        end

        def play_relations=(value)
          @play_relations = build_artifact(value)
        end

        def play_solutions=(value)
          @play_solutions = build_artifact(value)
        end

        def playlists=(value)
          @playlists = build_artifact(value)
        end

        def schedule_constraints=(value)
          @schedule_constraints = build_artifact(value)
        end

        def plan_json=(value)
          @plan_json = build_artifact(value)
        end

        private

        def build_artifact(value)
          return nil if value.nil?

          if value.is_a?(Array)
            value.map { |artifact| Artifact.new(artifact) }
          else
            Artifact.new(value)
          end
        end

        # Represents a downloadable artifact (JSON, playlist, etc.) returned by the export.
        class Artifact < Base
          attr_accessor :md5, :file_name, :url, :program_name

          attr_writer :support_md5_checkout

          def support_md5_checkout
            return nil if @support_md5_checkout.nil?

            !!@support_md5_checkout
          end

          def support_md5_checkout?
            support_md5_checkout
          end

          # Legacy camelCase accessors for backward compatibility with existing clients.
          # Legacy camelCase accessors for backward compatibility with existing clients.
          # rubocop:disable Naming/PredicatePrefix
          def is_support_md5_checkout?
            support_md5_checkout?
          end

          def is_support_md5_checkout=(value)
            self.support_md5_checkout = value
          end
          # rubocop:enable Naming/PredicatePrefix
        end
      end
    end
  end
end
