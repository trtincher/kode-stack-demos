module ChartQueue::BoardHelper
  # Literal class strings so the Tailwind scanner keeps them.
  CODER_COLORS = {
    "indigo" => "bg-indigo-100 text-indigo-800",
    "emerald" => "bg-emerald-100 text-emerald-800",
    "amber" => "bg-amber-100 text-amber-900",
    "rose" => "bg-rose-100 text-rose-800"
  }.freeze

  def queue_coder_chip(coder)
    classes = CODER_COLORS.fetch(coder&.color, "bg-slate-100 text-slate-700")
    tag.span coder&.name || "Unknown", class: "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{classes}"
  end

  def queue_payout(chart)
    number_to_currency(chart.payout)
  end

  def queue_due(chart)
    words = distance_of_time_in_words(Time.current, chart.due_at)
    chart.due_at.future? ? "due in #{words}" : "overdue by #{words}"
  end

  def queue_toast_class(tone)
    tone == :warning ? "bg-amber-50 text-amber-900 ring-amber-200" : "bg-emerald-50 text-emerald-800 ring-emerald-200"
  end
end
