require "test_helper"

class Assistant::SuggestCodesJobTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "broadcasts running, one append per suggestion, the final list, then done" do
    request_id = SecureRandom.uuid
    stream = "assistant_request_#{request_id}"
    note = "Home readings average 152/94 and she has essential hypertension. She smokes half a pack of cigarettes a day."

    assert_broadcasts(stream, 5) do
      Assistant::SuggestCodesJob.perform_now(request_id: request_id, note: note)
    end

    messages = broadcasts(stream)
    assert_includes messages.first, "Running"
    assert_includes messages.second, "KX-C101"
    assert_includes messages.third, "KX-Z901"
    final_list = ActiveSupport::JSON.decode(messages.fourth)
    assert_includes final_list, %(action="replace" target="assistant_suggestions")
    assert_includes final_list, "KX-C101"
    assert_includes final_list, "KX-Z901"
    assert_includes messages.last, "2 codes suggested"
  end
end
