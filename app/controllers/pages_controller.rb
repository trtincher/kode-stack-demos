class PagesController < ApplicationController
  def home
    @status = StatusCheck.new
  end

  # Enqueues a heartbeat; the job broadcasts the refreshed panel back.
  def heartbeat
    HeartbeatJob.perform_later
    redirect_to root_path, notice: "Heartbeat job enqueued."
  end
end
