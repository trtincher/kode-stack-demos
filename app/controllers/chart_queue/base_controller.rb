# Who is clicking. Two tabs in one browser share a cookie session, so the coder
# rides in the URL (?as=maya) and in a hidden `as` field on every form; the
# session only remembers the last pick so a fresh tab opens as someone.
class ChartQueue::BaseController < ApplicationController
  helper_method :current_coder, :coders

  private

  def current_coder
    return @current_coder if defined?(@current_coder)

    @current_coder = ChartQueue::Coder.find_by(slug: params[:as].presence || session[:queue_coder])
    session[:queue_coder] = @current_coder.slug if @current_coder
    @current_coder
  end

  def coders
    @coders ||= ChartQueue::Coder.order(:name).to_a
  end
end
