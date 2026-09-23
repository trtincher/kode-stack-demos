require "test_helper"

class Assistant::ScoringTest < ActiveSupport::TestCase
  test "scores exact-match code sets by precision, recall, and F1" do
    score = Assistant::Scoring.score(expected: %w[KX-C101 KX-C102 KX-Z901], got: %w[KX-C101 KX-C102 KX-C110 KX-R301])

    assert_in_delta 0.5, score.precision
    assert_in_delta 0.6667, score.recall
    assert_in_delta 0.5714, score.f1
    assert_not score.passed?

    assert Assistant::Scoring.score(expected: [], got: []).passed?, "an empty answer to a note with no codes is correct"
    assert_equal 0.0, Assistant::Scoring.score(expected: [], got: %w[KX-M201]).f1
  end
end
