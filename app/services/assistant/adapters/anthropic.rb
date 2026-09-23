module Assistant
  module Adapters
    # Calls Claude with a single forced tool whose schema only admits catalog
    # codes. Output is capped at 1024 tokens and thinking is disabled so the
    # whole budget goes to the tool call.
    class Anthropic
      DEFAULT_MODEL = "claude-sonnet-5"
      MAX_TOKENS = 1024

      TOOL = {
        name: "suggest_codes",
        description: "Report the catalog codes this encounter note supports, each with a confidence and the sentence that supports it.",
        strict: true,
        input_schema: {
          type: "object",
          additionalProperties: false,
          required: [ "suggestions" ],
          properties: {
            suggestions: {
              type: "array",
              items: {
                type: "object",
                additionalProperties: false,
                required: %w[code description confidence evidence],
                properties: {
                  code: { type: "string", enum: CodeCatalog.codes, description: "A code from the catalog." },
                  description: { type: "string", description: "The catalog description of the code." },
                  confidence: { type: "number", description: "How sure you are, from 0 to 1." },
                  evidence: { type: "string", description: "The sentence from the note, quoted exactly, that supports the code." }
                }
              }
            }
          }
        }
      }.freeze

      def initialize(client: nil, model: ENV.fetch("MODEL_ID", DEFAULT_MODEL))
        @client = client || ::Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"], max_retries: 2, timeout: 30)
        @model = model
      end

      def label = "anthropic:#{@model}"

      def suggest(note:, prompt:)
        message = @client.messages.create(
          model: @model,
          max_tokens: MAX_TOKENS,
          thinking: { type: "disabled" },
          system_: "#{prompt}\n\nCode catalog:\n#{CodeCatalog.to_prompt}",
          tools: [ TOOL ],
          tool_choice: { type: "tool", name: TOOL[:name] },
          messages: [ { role: "user", content: "<note>\n#{note}\n</note>" } ]
        )

        raise AdapterError, "The model declined this note." if message.stop_reason == :refusal
        raise AdapterError, "The model ran out of tokens before finishing." if message.stop_reason == :max_tokens

        tool_use = message.content.find { |block| block.type == :tool_use && block.name == TOOL[:name] }
        raise AdapterError, "The model did not call suggest_codes." unless tool_use

        input = JSON.parse(tool_use.input.to_json)
        ModelAdapter.normalize(input["suggestions"], note: note)
      rescue ::Anthropic::Errors::RateLimitError
        raise AdapterError, "The model is rate limited; try again in a minute."
      rescue ::Anthropic::Errors::APIStatusError, ::Anthropic::Errors::APIConnectionError => e
        raise AdapterError, "The model call failed (#{e.class.name.demodulize})."
      end
    end
  end
end
