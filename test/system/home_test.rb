require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "the index lists every demo and the status panel renders in a real browser" do
    visit root_path

    assert_selector "h1", text: "Kode Stack Demos"
    DEMOS.each { |demo| assert_link demo[:title], href: demo[:path] }
    assert_selector "#status_panel", text: "PostgreSQL"
  end
end
