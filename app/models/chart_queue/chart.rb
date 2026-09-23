# A synthetic chart waiting to be coded. The claim lives on the row itself
# (coder_id, claimed_at, claim_expires_at), so the row lock taken while
# claiming is the whole concurrency story.
class ChartQueue::Chart < ApplicationRecord
  self.table_name = "queue_charts"

  CLAIM_SLA = 3.minutes
  # Every open board subscribes to this one Turbo Streams channel.
  STREAM = "queue_board".freeze
  STATUSES = %w[available claimed done].freeze

  belongs_to :coder, class_name: "ChartQueue::Coder", optional: true

  validates :status, inclusion: { in: STATUSES }

  scope :available, -> { where(status: "available") }
  scope :claimed, -> { where(status: "claimed") }
  scope :done, -> { where(status: "done") }
  scope :expired, ->(now = Time.current) { claimed.where(claim_expires_at: ..now) }

  after_update_commit :broadcast_move, if: :saved_change_to_status?
  after_update_commit :schedule_release, if: -> { saved_change_to_status? && claimed? }

  class << self
    # Claims one specific chart. SKIP LOCKED means a concurrent claimer never
    # waits on this row: while another transaction holds it, it is skipped;
    # once that commits, it is no longer available. Either way the loser gets
    # nil back instead of an error or a double claim.
    def claim!(id, coder)
      claim_first(available.where(id: id), coder)
    end

    # Claims the most urgent chart nobody else is holding. Two coders clicking
    # at the same moment get two different charts.
    def claim_next!(coder)
      claim_first(available.order(:due_at, :id), coder)
    end

    # Rows for each column, in display order.
    def by_column
      {
        "available" => available.order(:due_at, :id).to_a,
        "claimed" => claimed.includes(:coder).order(claimed_at: :desc).to_a,
        "done" => done.includes(:coder).order(completed_at: :desc).to_a
      }
    end

    def counts
      STATUSES.index_with(0).merge(group(:status).count)
    end

    private

    def claim_first(relation, coder)
      transaction do
        chart = relation.lock("FOR UPDATE SKIP LOCKED").first
        next unless chart

        now = Time.current
        chart.update!(status: "claimed", coder: coder, claimed_at: now, claim_expires_at: now + CLAIM_SLA)
        chart
      end
    end
  end

  STATUSES.each { |name| define_method(:"#{name}?") { status == name } }

  def held_by?(coder) = claimed? && coder.present? && coder_id == coder.id

  # Complete and release re-read the row under FOR UPDATE, so they act on the
  # committed claim rather than on whatever this object loaded earlier.
  def complete!(by:)
    with_lock do
      held_by?(by) && update!(status: "done", completed_at: Time.current, claim_expires_at: nil)
    end
  end

  # by: nil is the SLA job releasing on the system's behalf.
  def release!(by: nil)
    with_lock do
      claimed? && (by.nil? || held_by?(by)) &&
        update!(status: "available", coder: nil, claimed_at: nil, claim_expires_at: nil)
    end
  end

  def payout = payout_cents / 100.0

  private

  # One message on the board's stream: take the row out of its old column,
  # put it in its new one, refresh the counts. The claimer's own response
  # renders the same partial, so both paths show the same thing.
  def broadcast_move
    broadcast_render_to STREAM, partial: "chart_queue/charts/moved", locals: { chart: self }
  end

  # A wake-up at this claim's deadline. The job sweeps every expired claim, so
  # a duplicate or late run is harmless.
  def schedule_release
    ChartQueue::ReleaseExpiredClaimsJob.set(wait_until: claim_expires_at + 1.second).perform_later
  end
end
