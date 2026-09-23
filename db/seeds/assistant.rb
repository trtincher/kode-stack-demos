# Synthetic data only. Resets the assistant demo: clears its tables, loads the
# golden set from db/seeds/assistant_golden.yml, and creates prompt version 1.
module Seeds::Assistant
  def self.reset!
    ActiveRecord::Base.connection.truncate_tables(
      "assistant_eval_results", "assistant_eval_runs", "assistant_eval_cases", "assistant_prompt_versions"
    )

    YAML.safe_load_file(Rails.root.join("db/seeds/assistant_golden.yml")).each_with_index do |row, index|
      ::Assistant::EvalCase.create!(
        key: row.fetch("key"),
        title: row.fetch("title"),
        note: row.fetch("note").squish,
        expected_codes: row.fetch("expected"),
        showcase: row.fetch("showcase", false),
        position: index
      )
    end

    ::Assistant::PromptVersion.create!(version: 1, body: ::Assistant::PromptVersion::DEFAULT_BODY)
  end
end
