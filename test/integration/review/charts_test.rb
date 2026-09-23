require "test_helper"

class Review::ChartsTest < ActionDispatch::IntegrationTest
  test "the coder can't approve, and the index counts charts by state" do
    chart = Review::Chart.create!(patient_initials: "T.T.", specialty: "Cardiology", encounter_summary: "Synthetic visit.")
    chart.codes.create!(code: "I10", description: "Essential (primary) hypertension", position: 1)
    chart.submit!

    patch review_role_path, params: { role: "coder" }
    patch approve_review_chart_path(chart)
    follow_redirect!

    assert chart.reload.in_review?
    assert_select "#review_flash", text: /Only the reviewer can approve/

    get review_root_path
    assert_select "#state-in_review .badge-info", text: "1"
    assert_select "#state-approved .badge-success", text: "0"
  end
end
