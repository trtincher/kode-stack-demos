# "Reset demo": put the review demo's synthetic charts back to their start.
class Review::ResetsController < Review::BaseController
  def create
    Seeds.load_all! unless Seeds.for("review")
    Seeds.for("review").reset!
    redirect_to review_root_path, flash: { review_notice: "Demo reset: 8 synthetic charts reseeded." }
  end
end
