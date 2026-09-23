module Assistant
  # How one case scored in one run. Expected codes are copied in so a later
  # reseed cannot rewrite a finished run.
  class EvalResult < ApplicationRecord
    self.table_name = "assistant_eval_results"

    belongs_to :eval_run, class_name: "Assistant::EvalRun"
    belongs_to :eval_case, class_name: "Assistant::EvalCase"

    def hits = expected_codes & got_codes
    def missed = expected_codes - got_codes
    def spurious = got_codes - expected_codes
  end
end
