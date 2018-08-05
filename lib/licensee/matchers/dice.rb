module Licensee
  module Matchers
    class Dice < Licensee::Matchers::Matcher
      # Return the first potential license that is more similar
      # than the confidence threshold
      def match
        @match ||= if matches.empty?
          nil
        else
          matches.first[0]
        end
      end

      # Licenses that may be a match for this file.
      # To avoid false positives:
      #
      # 1. Creative commons licenses cannot be matched against license files
      #    that begin with the title of a non-open source CC license variant
      # 2. The percentage change in file length may not exceed the inverse
      #    of the confidence threshold
      def potential_licenses
        @potential_licenses ||= begin
          Licensee.licenses(hidden: true).select do |license|
            if license.creative_commons? && file.potential_false_positive?
              false
            else
              license.wordset && license.length_delta(file) <= license.max_delta
            end
          end
        end
      end

      def matches_by_similarity
        @matches_by_similarity ||= begin
          matches = potential_matches.map do |potenial_match|
            [potenial_match, potenial_match.similarity(file)]
          end
          matches.sort_by { |_, similarity| similarity }.reverse
        end
      end
      alias licenses_by_similarity matches_by_similarity

      def matches
        @matches ||= matches_by_similarity.select do |_, similarity|
          similarity >= Licensee.confidence_threshold
        end
      end

      # Confidence that the matched license is a match
      def confidence
        @confidence ||= match ? file.similarity(match) : 0
      end
    end
  end
end
