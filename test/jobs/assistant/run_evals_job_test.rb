require "test_helper"

class Assistant::RunEvalsJobTest < ActiveSupport::TestCase
  setup do
    Seeds.load_all!
    Seeds::Assistant.reset!
  end

  test "scores the golden set, summarizes the run, and reports the delta against another prompt version" do
    v1_run = run_evals
    assert_equal "done", v1_run.status
    assert_equal Assistant::EvalCase.count, v1_run.eval_results.count
    assert_equal 19, v1_run.passed_count, "the Fake adapter codes denied and ruled-out findings under v1"
    assert_nil v1_run.delta, "no other prompt version to compare with yet"

    Assistant::PromptVersion.create_next!("#{Assistant::PromptVersion.current.body}\n#{Assistant::PromptVersion::NEGATION_HINT}")
    v2_run = run_evals

    assert_equal 28, v2_run.passed_count, "only the two family-history cases still fail"
    assert_equal v1_run, v2_run.delta[:baseline]
    assert_in_delta 0.3, v2_run.delta[:pass_rate]
    assert_in_delta v2_run.mean_f1 - v1_run.mean_f1, v2_run.delta[:mean_f1], 0.0001
  end

  private

  def run_evals
    run = Assistant::EvalRun.create!(prompt_version: Assistant::PromptVersion.current, adapter: "fake")
    Assistant::RunEvalsJob.perform_now(run.id)
    run.reload
  end
end
