module Assistant
  # One suggested code. `evidence` is the sentence from the note the adapter
  # says supports the code; `evidence_found` is false when that sentence is not
  # actually in the note (the hallucination guard the UI flags).
  Suggestion = Struct.new(:code, :description, :confidence, :evidence, :evidence_found, keyword_init: true) do
    def self.from_raw(raw, note:)
      raw = raw.to_h.transform_keys(&:to_s)
      code = raw["code"].to_s
      evidence = raw["evidence"].to_s.strip
      new(
        code: code,
        description: CodeCatalog.description_for(code) || raw["description"].to_s,
        confidence: raw["confidence"].to_f.clamp(0.0, 1.0).round(2),
        evidence: evidence,
        evidence_found: evidence.present? && squish(note).include?(squish(evidence))
      )
    end

    def self.squish(text) = text.to_s.squish.downcase

    def confidence_level
      if confidence >= 0.75 then :high
      elsif confidence >= 0.5 then :medium
      else :low
      end
    end

    def as_json(*) = to_h.transform_keys(&:to_s)
  end
end
