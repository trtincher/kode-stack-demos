module PagesHelper
  # Stubs for the three demo features; each lands in its own follow-up circle.
  DEMOS = [
    { name: "Chart queue", blurb: "Turbo Streams claim board with SKIP LOCKED and SLA release jobs." },
    { name: "Coding assistant", blurb: "Streaming model suggestions with an evals tab over a golden set." },
    { name: "Review workflow", blurb: "State machine, inline Turbo Frame edits, versioned audit history." }
  ].freeze

  def demos
    DEMOS
  end
end
