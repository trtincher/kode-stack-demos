module Assistant
  # Runs every golden case against the run's prompt version, one at a time,
  # scoring each and re-broadcasting the run panel after every case so the
  # progress bar moves. The panel is always rendered from the database, so a
  # page that subscribes late catches up on the next case.
  class RunEvalsJob < ApplicationJob
    queue_as :default

    def perform(eval_run_id)
      run = EvalRun.find_by(id: eval_run_id)
      return unless run&.status == "queued"

      adapter = ModelAdapter.current
      run.update!(status: "running", started_at: Time.current, adapter: adapter.label, cases_total: EvalCase.count)
      broadcast(run)

      EvalCase.ordered.each do |eval_case|
        score_case(run, eval_case, adapter)
        run.summarize!
        broadcast(run)
      end

      run.update!(status: "done", finished_at: Time.current)
      broadcast(run)
    rescue ActiveRecord::RecordNotFound, ActiveRecord::InvalidForeignKey
      # The demo was reset mid-run; the run is gone with everything else.
    rescue StandardError => e
      Rails.logger.error("[assistant] eval run #{eval_run_id} failed: #{e.class}: #{e.message}")
      if run&.persisted?
        run.update_columns(status: "failed", error: "The run stopped: #{e.class.name.demodulize}", finished_at: Time.current)
        broadcast(run)
      end
    end

    private

    def score_case(run, eval_case, adapter)
      suggestions = adapter.suggest(note: eval_case.note, prompt: run.prompt_version.body)
      record(run, eval_case, suggestions: suggestions)
    rescue AdapterError => e
      record(run, eval_case, suggestions: [], error: e.message)
    end

    def record(run, eval_case, suggestions:, error: nil)
      got = suggestions.map(&:code)
      score = Scoring.score(expected: eval_case.expected_codes, got: got)
      run.eval_results.create!(
        eval_case: eval_case,
        expected_codes: eval_case.expected_codes,
        got_codes: got,
        suggestions: suggestions.map(&:as_json),
        precision: score.precision,
        recall: score.recall,
        f1: score.f1,
        passed: error.nil? && score.passed?,
        error: error
      )
    end

    def broadcast(run)
      Turbo::StreamsChannel.broadcast_replace_to(
        run.stream_name, target: ActionView::RecordIdentifier.dom_id(run),
        partial: "assistant/eval_runs/run", locals: { run: run }
      )
    end
  end
end
