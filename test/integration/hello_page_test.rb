require "test_helper"

class HelloPageTest < ActionDispatch::IntegrationTest
  test "home is the demo index: a card per registered demo plus the scaffold health panel" do
    get root_path

    assert_response :success
    assert_select "h1", text: "Kode Stack Demos"
    DEMOS.each do |demo|
      assert_select "a.card-link[href=?]", demo[:path], text: /#{Regexp.escape(demo[:title])}/
      assert_select "nav a[href=?]", demo[:path]
    end
    assert_select "#status_panel"
  end
end
