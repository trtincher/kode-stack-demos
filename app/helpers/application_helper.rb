module ApplicationHelper
  def status_badge(ok)
    tag.span ok ? "reachable" : "unreachable", class: ok ? "badge-success" : "badge-danger"
  end

  # Shared-nav link, highlighted when the current page sits under `path`.
  def nav_link(label, path)
    active = path == "/" ? request.path == "/" : request.path.start_with?(path)
    link_to label, path, class: active ? "nav-link-active" : "nav-link", aria: { current: ("page" if active) }
  end
end
