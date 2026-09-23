# A coded chart moving through QA review. The state machine is the contract:
# only listed transitions exist, guards refuse the ones that would leave the
# record dishonest (submitting nothing, returning without saying why), and
# PaperTrail records every step.
class Review::Chart < ApplicationRecord
  include AASM

  self.table_name = "review_charts"

  has_many :codes, -> { order(:position) }, class_name: "Review::Code", inverse_of: :chart, dependent: :destroy

  has_paper_trail versions: { class_name: "Review::Version" },
                  only: %i[state return_note],
                  meta: { chart_id: :id }

  validates :patient_initials, :specialty, :encounter_summary, presence: true

  aasm column: :state, whiny_transitions: true do
    state :draft, initial: true
    state :in_review
    state :returned
    state :approved

    event :submit do
      transitions from: %i[draft returned], to: :in_review, guard: :has_codes?
    end

    event :return_to_coder do
      transitions from: :in_review, to: :returned, guard: :return_note?
    end

    # approved is terminal: no event leaves it.
    event :approve do
      transitions from: :in_review, to: :approved
    end
  end

  STATE_LABELS = { "draft" => "Draft", "in_review" => "In review", "returned" => "Returned", "approved" => "Approved" }.freeze
  STATE_BADGES = { "draft" => "badge", "in_review" => "badge-info", "returned" => "badge-warning", "approved" => "badge-success" }.freeze

  def self.states = aasm.states.map { |state| state.name.to_s }

  def state_label = STATE_LABELS.fetch(state)
  def state_badge = STATE_BADGES.fetch(state)

  def title = "#{patient_initials} · #{specialty}"

  # Strict gating: the reviewer edits while the chart is under review; the
  # coder edits before submitting and after a return. Approved is frozen.
  def editable_by?(role)
    role.reviewer? ? in_review? : (draft? || returned?)
  end

  private

  def has_codes? = codes.exists?
end
