require "test_helper"

class HelloPageTest < ActionDispatch::IntegrationTest
  test "renders the app name, the three demo entries, and the status panel" do
    get root_path

    assert_response :success
    assert_select "h1", text: "Kode Stack Demos"
    PagesHelper::DEMOS.each { |demo| assert_select "nav a", text: demo[:name] }
    assert_select "#status_panel"
  end
end
