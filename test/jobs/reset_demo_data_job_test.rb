require "test_helper"

class ResetDemoDataJobTest < ActiveSupport::TestCase
  # Runs against whatever db/seeds/*.rb exist; with none, every demo is skipped
  # (and Seeds::Queue must not resolve to Ruby's top-level ::Queue).
  test "walks the registry, resetting only demos that ship a seed module" do
    Seeds.load_all! # seed modules are only defined once their files are loaded
    shipped = DEMOS.map { |demo| demo[:key] }.select { |key| Seeds.for(key) }

    assert_nil Seeds.for("no_such_demo")
    assert_equal shipped, ResetDemoDataJob.perform_now
  end
end
