module Assistant
  # Picks the adapter: Claude when an API key is configured, otherwise the
  # deterministic Fake. Tests always get the Fake, so CI never calls a model.
  module ModelAdapter
    def self.current
      if ENV["ANTHROPIC_API_KEY"].present? && !Rails.env.test?
        Adapters::Anthropic.new
      else
        Adapters::Fake.new
      end
    end

    # Shared post-processing: build Suggestions, keep catalog codes only, one
    # suggestion per code, highest confidence first.
    def self.normalize(raw_suggestions, note:)
      Array(raw_suggestions)
        .map { |raw| Suggestion.from_raw(raw, note: note) }
        .select { |suggestion| CodeCatalog.find(suggestion.code) }
        .uniq(&:code)
        .sort_by { |suggestion| [ -suggestion.confidence, suggestion.code ] }
    end
  end
end
