module Assistant
  module Adapters
    # Deterministic stand-in for the model, used in tests and whenever no API
    # key is set. It matches catalog keywords sentence by sentence, so it has
    # a keyword matcher's blind spots: it codes family history, and it codes
    # denied or ruled-out findings unless the prompt tells it not to. That one
    # prompt sensitivity is deliberate, so the Evals tab shows a real delta
    # when a visitor adds the negation instruction offline.
    class Fake
      NEGATION_CUE = /\b(denies|denied|ruled out|negative for)\b/i
      NEGATION_INSTRUCTION = /\b(do not|don't|never|exclude|skip)\b[^\n]*\b(denied|ruled out|negative)\b/i

      def label = "fake"

      def suggest(note:, prompt:)
        sentences = split_sentences(note)
        sentences = sentences.grep_v(NEGATION_CUE) if prompt.to_s.match?(NEGATION_INSTRUCTION)

        raw = CodeCatalog::ENTRIES.filter_map do |entry|
          matching = sentences.select { |sentence| mentions?(sentence, entry.keywords) }
          next if matching.empty?

          {
            code: entry.code,
            description: entry.description,
            confidence: [ 0.6 + 0.15 * (matching.size - 1), 0.95 ].min,
            evidence: matching.first
          }
        end
        ModelAdapter.normalize(raw, note: note)
      end

      private

      def split_sentences(note)
        note.to_s.squish.split(/(?<=[.!?])\s+/).reject(&:blank?)
      end

      def mentions?(sentence, keywords)
        keywords.any? { |keyword| sentence.match?(/\b#{Regexp.escape(keyword)}\b/i) }
      end
    end
  end
end
