module Assistant
  # One pass of the golden set against a prompt version.
  class EvalRun < ApplicationRecord
    self.table_name = "assistant_eval_runs"

    STATUSES = %w[queued running done failed].freeze

    belongs_to :prompt_version, class_name: "Assistant::PromptVersion"
    has_many :eval_results, -> { order(:id) }, class_name: "Assistant::EvalResult", dependent: :delete_all

    validates :status, inclusion: { in: STATUSES }

    scope :active, -> { where(status: %w[queued running]) }
    scope :recent, -> { order(created_at: :desc) }

    def stream_name = "assistant_eval_run_#{id}"
    def done? = status == "done"
    def active? = status.in?(%w[queued running])

    def pass_rate
      return nil if cases_done.zero?

      passed_count.to_f / cases_done
    end

    def progress_percent
      return 0 if cases_total.zero?

      (100.0 * cases_done / cases_total).round
    end

    # The latest finished run of a different prompt version: the baseline a
    # prompt change is judged against.
    def previous_comparable_run
      self.class.where(status: "done")
        .where.not(prompt_version_id: prompt_version_id)
        .where(created_at: ...created_at)
        .order(created_at: :desc)
        .first
    end

    # Change against the baseline, or nil when there is none yet.
    def delta
      baseline = previous_comparable_run
      return unless done? && baseline

      {
        baseline: baseline,
        mean_f1: (mean_f1 - baseline.mean_f1).to_f.round(4),
        pass_rate: (pass_rate - baseline.pass_rate).round(4)
      }
    end

    # Recomputes the summary from the stored per-case results.
    def summarize!
      results = eval_results.reload
      count = results.size
      update!(
        cases_done: count,
        passed_count: results.count(&:passed),
        mean_precision: count.zero? ? 0 : results.sum(&:precision) / count,
        mean_recall: count.zero? ? 0 : results.sum(&:recall) / count,
        mean_f1: count.zero? ? 0 : results.sum(&:f1) / count
      )
    end
  end
end
