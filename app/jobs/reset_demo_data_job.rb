# Puts every demo back to its synthetic starting state. Runs the same registry
# loop as db/seeds.rb; demos without a seed module are skipped.
class ResetDemoDataJob < ApplicationJob
  queue_as :low

  def perform
    Seeds.reset_all!
  end
end
