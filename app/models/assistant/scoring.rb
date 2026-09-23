module Assistant
  # Exact-match set scoring on codes. Two empty sets agree perfectly; one empty
  # set against a non-empty one scores zero.
  module Scoring
    Score = Data.define(:precision, :recall, :f1) do
      def passed? = f1 >= 1.0
    end

    def self.score(expected:, got:)
      expected = expected.to_set
      got = got.to_set
      return Score.new(1.0, 1.0, 1.0) if expected.empty? && got.empty?

      hits = (expected & got).size.to_f
      precision = got.empty? ? 0.0 : hits / got.size
      recall = expected.empty? ? 0.0 : hits / expected.size
      f1 = (precision + recall).zero? ? 0.0 : 2 * precision * recall / (precision + recall)
      Score.new(precision.round(4), recall.round(4), f1.round(4))
    end
  end
end
