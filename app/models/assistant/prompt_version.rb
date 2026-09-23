module Assistant
  # Prompt text, versioned. Versions are immutable: editing the prompt creates
  # the next version, and the highest version is the one in use.
  class PromptVersion < ApplicationRecord
    self.table_name = "assistant_prompt_versions"

    MAX_BODY = 4_000

    DEFAULT_BODY = <<~PROMPT.strip
      You are a medical coding assistant reviewing a synthetic encounter note.
      Call the suggest_codes tool with every code from the catalog that the note supports.
      For each code, give a confidence between 0 and 1, and quote word for word the one sentence from the note that supports it as the evidence.
      Use only codes from the catalog.
    PROMPT

    # The line the Evals tab nudges visitors to add. The Fake adapter honours it.
    NEGATION_HINT = "Do not code conditions the note says are denied, ruled out, or negative."

    has_many :eval_runs, class_name: "Assistant::EvalRun", dependent: :destroy

    validates :version, presence: true, uniqueness: true
    validates :body, presence: true, length: { maximum: MAX_BODY }

    def self.current = order(version: :desc).first

    def self.create_next!(body)
      create!(version: (maximum(:version) || 0) + 1, body: body.to_s.strip)
    end
  end
end
