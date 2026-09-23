# Shared plumbing for the review demo: the session role toggle and PaperTrail
# attribution. Every version written during a request is stamped with the
# acting role and its synthetic name.
class Review::BaseController < ApplicationController
  before_action :set_paper_trail_whodunnit

  helper_method :current_role

  private

  def current_role
    @current_role ||= Review::Role.find(session[:review_role])
  end

  def user_for_paper_trail
    current_role.whodunnit
  end
end
