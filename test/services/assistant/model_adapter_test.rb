require "test_helper"

class Assistant::ModelAdapterTest < ActiveSupport::TestCase
  test "tests always get the Fake adapter, even with an API key set" do
    previous = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "sk-test-not-a-real-key"

    assert_instance_of Assistant::Adapters::Fake, Assistant::ModelAdapter.current
  ensure
    ENV["ANTHROPIC_API_KEY"] = previous
  end

  # A stubbed client stands in for the API: checks the request shape we
  # constrain the model with, and that a quote not in the note is flagged.
  test "the Claude adapter forces the suggest_codes tool and flags evidence missing from the note" do
    note = "Patient has essential hypertension. She smokes daily."
    tool_use = Struct.new(:type, :name, :input).new(:tool_use, "suggest_codes", {
      suggestions: [
        { code: "KX-C101", description: "x", confidence: 1.4, evidence: "Patient has essential hypertension." },
        { code: "KX-Z901", description: "x", confidence: 0.7, evidence: "She smokes a pack a day." }
      ]
    })
    requests = []
    client = Object.new
    messages = Object.new
    messages.define_singleton_method(:create) do |**params|
      requests << params
      Struct.new(:stop_reason, :content).new(:tool_use, [ tool_use ])
    end
    client.define_singleton_method(:messages) { messages }

    suggestions = Assistant::Adapters::Anthropic.new(client: client, model: "claude-sonnet-5").suggest(note: note, prompt: "Code it.")

    request = requests.sole
    assert_equal({ type: "tool", name: "suggest_codes" }, request[:tool_choice])
    assert_operator request[:max_tokens], :<=, 1024
    assert_equal Assistant::CodeCatalog.codes, request[:tools].sole.dig(:input_schema, :properties, :suggestions, :items, :properties, :code, :enum)

    assert_equal %w[KX-C101 KX-Z901], suggestions.map(&:code)
    assert_equal 1.0, suggestions.first.confidence
    assert suggestions.first.evidence_found
    assert_not suggestions.last.evidence_found
  end
end
