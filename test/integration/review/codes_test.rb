require "test_helper"

class Review::CodesTest < ActionDispatch::IntegrationTest
  test "a reviewer's inline code edit writes a PaperTrail version stamped with the session role" do
    chart = Review::Chart.create!(patient_initials: "T.T.", specialty: "Cardiology", encounter_summary: "Synthetic visit.")
    code = chart.codes.create!(code: "I10", description: "Essential (primary) hypertension", position: 1)
    chart.submit!

    patch review_role_path, params: { role: "reviewer" }
    patch review_chart_code_path(chart, code), params: { review_code: { code: "I11.9" } }, as: :turbo_stream

    assert_response :success
    assert_match %(turbo-stream action="replace" target="#{ActionView::RecordIdentifier.dom_id(code)}"), response.body
    version = Review::Version.where(item: code, event: "update").last
    assert_equal "Reviewer · Dana Okafor", version.whodunnit
    assert_equal chart.id, version.chart_id
    assert_equal %w[I10 I11.9], version.object_changes["code"]
  end
end
