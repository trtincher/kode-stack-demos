# Every action answers with the same "moved" stream the model broadcasts, plus
# a note for this tab only. Losing a race is not an error: the row simply shows
# who has it now.
class ChartQueue::ChartsController < ChartQueue::BaseController
  before_action :require_coder

  def claim
    @chart = ChartQueue::Chart.claim!(params[:id], current_coder)
    if @chart
      respond("#{@chart.reference} is yours for #{sla_minutes} minutes.")
    else
      @chart = ChartQueue::Chart.find(params[:id])
      holder = @chart.coder&.first_name || "Someone"
      respond("#{holder} got there first. #{@chart.reference} is theirs.", tone: :warning)
    end
  end

  def claim_next
    @chart = ChartQueue::Chart.claim_next!(current_coder)
    if @chart
      respond("#{@chart.reference} is yours for #{sla_minutes} minutes.")
    else
      respond("Nothing left to claim. Reset the demo to refill the queue.", tone: :warning)
    end
  end

  def complete
    @chart = ChartQueue::Chart.find(params[:id])
    if @chart.complete!(by: current_coder)
      respond("#{@chart.reference} coded and done. Nice work.")
    else
      respond("#{@chart.reference} is no longer yours to complete.", tone: :warning)
    end
  end

  def release
    @chart = ChartQueue::Chart.find(params[:id])
    if @chart.release!(by: current_coder)
      respond("#{@chart.reference} is back in the queue.")
    else
      respond("#{@chart.reference} is no longer yours to release.", tone: :warning)
    end
  end

  private

  def require_coder
    respond("Pick who you are first.", tone: :warning) unless current_coder
  end

  def respond(message, tone: :success)
    @message = message
    @tone = tone
    respond_to do |format|
      format.turbo_stream { render "chart_queue/charts/respond" }
      format.html { redirect_to queue_root_path(as: current_coder&.slug), notice: message }
    end
  end

  def sla_minutes = ChartQueue::Chart::CLAIM_SLA.in_minutes.to_i
end
