# The review demo's PaperTrail version. Includes the concern rather than
# subclassing PaperTrail::Version so the gem's default table is never touched.
class Review::Version < ApplicationRecord
  include PaperTrail::VersionConcern
  self.table_name = "review_versions"

  scope :timeline_for, ->(chart) { where(chart_id: chart.id).order(created_at: :desc, id: :desc) }
end
