module ApplicationHelper
  def status_badge(ok)
    classes = if ok
      "bg-emerald-50 text-emerald-700 ring-emerald-200"
    else
      "bg-rose-50 text-rose-700 ring-rose-200"
    end

    tag.span ok ? "reachable" : "unreachable",
      class: "rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 #{classes}"
  end
end
