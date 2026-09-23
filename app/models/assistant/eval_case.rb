module Assistant
  # One golden-set case: a synthetic note and the codes a careful coder would
  # assign. Showcase cases double as the Assistant tab's sample notes.
  class EvalCase < ApplicationRecord
    self.table_name = "assistant_eval_cases"

    MAX_NOTE = 2_000

    has_many :eval_results, class_name: "Assistant::EvalResult", dependent: :destroy

    validates :key, presence: true, uniqueness: true
    validates :title, presence: true
    validates :note, presence: true, length: { maximum: MAX_NOTE }

    scope :ordered, -> { order(:position, :id) }
    scope :showcase, -> { where(showcase: true).ordered }
  end
end
