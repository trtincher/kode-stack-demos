# The "You are: Coder | Reviewer" switch. Only the two known keys are stored.
class Review::RolesController < Review::BaseController
  def update
    session[:review_role] = Review::Role.find(params[:role]).key
    redirect_back_or_to review_root_path
  end
end
