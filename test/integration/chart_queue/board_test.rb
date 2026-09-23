require "test_helper"

class ChartQueue::BoardTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionCable::TestHelper

  setup do
    Seeds.load_all!
    Seeds::Queue.reset!
    @chart = ChartQueue::Chart.available.order(:due_at).first
  end

  test "the board renders three columns and a claim broadcasts to every tab" do
    get queue_root_path(as: "maya")

    assert_response :success
    assert_select "turbo-cable-stream-source"
    %w[available claimed done].each { |status| assert_select "#queue_column_#{status}" }
    assert_select "#queue_column_available ##{dom_id(@chart)}"

    assert_broadcasts(ChartQueue::Chart::STREAM, 1) do
      post claim_queue_chart_path(@chart), params: { as: "maya" }, as: :turbo_stream
    end
    assert_response :success
    assert_match(/turbo-stream action="prepend" target="queue_column_claimed"/, response.body)
    assert_equal "maya", @chart.reload.coder.slug
  end

  test "the losing click sees who has the chart, not an error" do
    post claim_queue_chart_path(@chart), params: { as: "maya" }, as: :turbo_stream

    assert_no_broadcasts(ChartQueue::Chart::STREAM) do
      post claim_queue_chart_path(@chart), params: { as: "dev" }, as: :turbo_stream
    end
    assert_response :success
    assert_match "Maya got there first", response.body
    assert_match "Claimed by", response.body
    assert_equal "maya", @chart.reload.coder.slug
  end
end
