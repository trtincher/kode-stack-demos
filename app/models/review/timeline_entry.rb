# Presents one Review::Version as a line on the chart's audit timeline:
# who, when, what kind of change, and a per-field diff.
class Review::TimelineEntry
  HIDDEN_FIELDS = %w[id chart_id created_at updated_at position].freeze
  EVENT_VERBS = { "in_review" => "submitted the chart for review", "returned" => "returned the chart to the coder",
                  "approved" => "approved the chart", "draft" => "created the chart" }.freeze

  attr_reader :version

  delegate :created_at, to: :version

  def initialize(version)
    @version = version
  end

  def self.for(chart) = Review::Version.timeline_for(chart).map { |version| new(version) }

  def role_label = whodunnit_parts.first
  def actor = whodunnit_parts.last

  def kind
    if chart?
      return :created if version.event == "create"
      changes.key?("state") ? :transition : :note
    else
      version.event == "create" ? :code_added : :code_edit
    end
  end

  def headline
    case kind
    when :created then "created the chart"
    when :transition then EVENT_VERBS.fetch(changes["state"].last, "moved the chart")
    when :note then "updated the return note"
    when :code_added then "added code #{code_value}"
    else "edited code #{code_value}"
    end
  end

  # [[field, before, after], ...] for fields a person would care about.
  def diffs
    return [] if kind == :created || kind == :code_added

    changes.except(*HIDDEN_FIELDS).map { |field, (before, after)| [ field.humanize, before, after ] }
  end

  def dom_id = "review_version_#{version.id}"

  private

  def chart? = version.item_type == "Review::Chart"

  def changes = version.object_changes || {}

  def code_value
    (changes["code"]&.last || version.object&.dig("code") || version.item&.code).to_s
  end

  def whodunnit_parts
    parts = version.whodunnit.to_s.split(" · ", 2)
    parts.size == 2 ? parts : [ "System", version.whodunnit.presence || "seed" ]
  end
end
