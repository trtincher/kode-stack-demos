require "application_system_test_case"

class ChartQueue::BoardSystemTest < ApplicationSystemTestCase
  setup do
    Seeds.load_all!
    Seeds::Queue.reset!
  end

  test "a coder claims a chart, watches the countdown, and completes it" do
    chart = ChartQueue::Chart.available.order(:due_at).first
    visit queue_root_path
    click_link "June Park"
    assert_selector "a[aria-current]", text: "June Park"

    within("#queue_column_available ##{dom_id(chart)}") { click_button "Claim" }

    within("#queue_column_claimed ##{dom_id(chart)}") do
      assert_text "June Park"
      assert_text(/\d:\d\d left/)
      click_button "Complete"
    end

    assert_selector "#queue_column_done ##{dom_id(chart)}", text: "June Park"
    assert_text "#{chart.reference} coded and done"
  end
end
