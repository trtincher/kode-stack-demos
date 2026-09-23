# The chart list (grouped by state) and one chart's review page, plus the
# three state-machine events. Each event checks the acting role, then lets
# aasm decide whether the transition is legal from the current state.
class Review::ChartsController < Review::BaseController
  VERBS = { submit: "submit", return_to_coder: "return", approve: "approve" }.freeze

  before_action :set_chart, except: :index

  def index
    charts = Review::Chart.includes(:codes).order(:updated_at).group_by(&:state)
    @groups = Review::Chart.states.map { |state| [ state, charts.fetch(state, []) ] }
    @counts = Review::Chart.group(:state).count
  end

  def show
    @codes = @chart.codes
    @timeline = Review::TimelineEntry.for(@chart)
  end

  def submit
    transition(:submit, role: :coder, done: "Submitted for review.")
  end

  def return_to_coder
    @chart.return_note = params.dig(:chart, :return_note).to_s.strip.presence
    transition(:return_to_coder, role: :reviewer, done: "Returned to the coder.",
               refused: "A return needs a note telling the coder what to fix.")
  end

  def approve
    transition(:approve, role: :reviewer, done: "Approved.")
  end

  private

  def set_chart
    @chart = Review::Chart.find(params[:id])
  end

  def transition(event, role:, done:, refused: nil)
    unless current_role.key == role.to_s
      alert = "Only the #{role} can #{VERBS[event]} a chart. Switch roles in the header."
      return redirect_to(review_chart_path(@chart), flash: { review_alert: alert })
    end

    @chart.public_send(:"#{event}!")
    redirect_to review_chart_path(@chart), flash: { review_notice: done }
  rescue AASM::InvalidTransition
    redirect_to review_chart_path(@chart), flash: { review_alert: refusal(event, refused) }
  end

  # Why aasm said no: either the event isn't defined from this state at all
  # (an illegal transition), or it is but a guard refused it.
  def refusal(event, guard_message)
    definition = Review::Chart.aasm.events.find { |e| e.name == event }
    unless definition.transitions_from_state?(@chart.aasm.current_state)
      return "Can't #{VERBS[event]} a chart that is #{@chart.state_label.downcase}."
    end

    guard_message || "Add at least one code before submitting."
  end
end
