require "test_helper"

class Review::ChartTest < ActiveSupport::TestCase
  setup do
    @chart = Review::Chart.create!(patient_initials: "T.T.", specialty: "Cardiology", encounter_summary: "Synthetic visit.")
    @chart.codes.create!(code: "I10", description: "Essential (primary) hypertension", position: 1)
  end

  test "walks draft → in_review → returned → in_review → approved, and approved is terminal" do
    assert @chart.draft?
    @chart.submit!
    assert @chart.in_review?

    @chart.return_note = "Add the laterality."
    @chart.return_to_coder!
    assert @chart.returned?

    @chart.submit!
    @chart.approve!
    assert @chart.reload.approved?
    assert_not @chart.may_submit?
    assert_not @chart.may_return_to_coder?
    assert_equal %w[draft in_review returned in_review approved],
                 [ "draft" ] + @chart.versions.filter_map { |v| v.object_changes&.dig("state", 1) }
  end

  test "refuses illegal transitions and guarded ones" do
    assert_raises(AASM::InvalidTransition) { @chart.approve! }
    assert @chart.reload.draft?

    @chart.submit!
    assert_raises(AASM::InvalidTransition) { @chart.return_to_coder! } # no note
    assert @chart.reload.in_review?

    empty = Review::Chart.create!(patient_initials: "N.C.", specialty: "Dermatology", encounter_summary: "No codes yet.")
    assert_not empty.may_submit?
  end
end
