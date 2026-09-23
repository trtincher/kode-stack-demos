require "application_system_test_case"

class AssistantTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper
  setup do
    Seeds.load_all!
    Seeds::Assistant.reset!
  end

  test "picking a sample note streams suggested codes back with evidence" do
    visit assistant_root_path
    assert_selector "turbo-cable-stream-source[connected]", visible: :all

    click_on "Blood pressure follow-up"
    click_on "Suggest codes"
    assert_selector "#assistant_status", text: "Queued"

    perform_enqueued_jobs

    assert_selector "#assistant_status", text: "3 codes suggested"
    within "#assistant_suggestions" do
      assert_selector "li", count: 3
      assert_selector "li", text: "KX-C101"
      assert_selector "mark", text: "she has essential hypertension on lisinopril"
    end
  end
end
