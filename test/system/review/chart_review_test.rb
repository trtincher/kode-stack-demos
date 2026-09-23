require "application_system_test_case"

class Review::ChartReviewTest < ApplicationSystemTestCase
  test "reviewer edits a code inline in its Turbo Frame and drives the page from the keyboard" do
    chart = Review::Chart.create!(patient_initials: "T.T.", specialty: "Cardiology", encounter_summary: "Synthetic visit.")
    code = chart.codes.create!(code: "I10", description: "Essential (primary) hypertension", position: 1)
    chart.submit!

    visit review_chart_path(chart)
    execute_script("window.reviewSentinel = 'same page'")

    find("body").send_keys("?")
    assert_selector "#review_shortcuts_legend", visible: true

    find("##{dom_id(code)} [data-review-shortcuts-target=row]").click # focus the row
    find("body").send_keys("e")
    fill_in "ICD-10-CM code", with: "I11.9"
    click_button "Save code"
    assert_no_field "ICD-10-CM code"
    assert_selector "##{dom_id(code)}", text: "I11.9"
    assert_equal dom_id(code), evaluate_script("document.activeElement.closest('turbo-frame')?.id"),
                 "focus should return to the saved row"

    assert_equal "same page", evaluate_script("window.reviewSentinel"), "the edit should not reload the page"
    assert_selector "#review_flash", text: "Saved I11.9"
    within("#review_timeline") { assert_text "edited code I11.9" }

    find("body").send_keys("a")
    assert_selector "#chart_state", text: "Approved"
    assert chart.reload.approved?
  end
end
