# Review demo seeds. Synthetic data only: patient initials and one-line
# encounter summaries are invented. The codes are real ICD-10-CM codes (a
# public code set) so the charts read plausibly.
#
# Each chart is walked through its real state-machine events under the right
# PaperTrail whodunnit, so the audit timeline shows a genuine history; the
# version timestamps are then spread over the last few hours so it reads like a
# working day rather than one instant.
module Seeds::Review
  CODER = "Coder · Sam Rivera".freeze
  REVIEWER = "Reviewer · Dana Okafor".freeze

  CHARTS = [
    { initials: "J.M.", specialty: "Family medicine", target: :draft,
      summary: "Annual visit. Type 2 diabetes stable on metformin; blood pressure at goal.",
      codes: [ [ "Z00.00", "Encounter for general adult medical examination without abnormal findings", "Routine annual exam, no new findings." ],
               [ "E11.9", "Type 2 diabetes mellitus without complications", "Documented T2DM, no complications noted." ] ] },
    { initials: "R.K.", specialty: "Dermatology", target: :draft,
      summary: "Follow-up for plaque psoriasis on elbows and knees; topical steroid refilled.",
      codes: [ [ "L40.0", "Psoriasis vulgaris", "Plaque psoriasis documented at both sites." ] ] },
    { initials: "A.T.", specialty: "Cardiology", target: :in_review,
      summary: "New-patient consult for palpitations; ECG shows atrial fibrillation, rate controlled.",
      codes: [ [ "I48.91", "Unspecified atrial fibrillation", "AF on ECG; type not specified in note." ],
               [ "I10", "Essential (primary) hypertension", "Long-standing HTN on medication." ],
               [ "R00.2", "Palpitations", "Presenting complaint." ] ] },
    { initials: "L.D.", specialty: "Orthopedics", target: :in_review,
      summary: "Right knee pain after a fall two weeks ago; X-ray negative, suspected sprain.",
      codes: [ [ "S83.91XA", "Sprain of unspecified site of right knee, initial encounter", "Sprain, initial visit for this injury." ],
               [ "W19.XXXA", "Unspecified fall, initial encounter", "Mechanism: fall." ] ] },
    { initials: "P.N.", specialty: "Pulmonology", target: :in_review,
      summary: "Asthma follow-up; mild intermittent symptoms, inhaler technique reviewed.",
      codes: [ [ "J45.20", "Mild intermittent asthma, uncomplicated", "Severity documented as mild intermittent." ] ] },
    { initials: "C.W.", specialty: "Emergency", target: :returned,
      summary: "Chest pain, troponin negative ×2, discharged with outpatient stress test.",
      codes: [ [ "R07.9", "Chest pain, unspecified", "No more specific chest pain type documented." ],
               [ "I10", "Essential (primary) hypertension", "History of HTN noted in HPI." ] ],
      return_note: "Note describes pain as pleuritic — consider R07.1 instead of R07.9, and confirm HTN is addressed this visit." },
    { initials: "M.S.", specialty: "Pediatrics", target: :approved,
      summary: "Well-child visit at 4 years; immunizations up to date, growth on curve.",
      codes: [ [ "Z00.129", "Encounter for routine child health examination without abnormal findings", "Routine well-child check." ],
               [ "Z23", "Encounter for immunization", "Vaccines given this visit." ] ] },
    { initials: "E.H.", specialty: "Endocrinology", target: :approved,
      summary: "Hypothyroidism follow-up; TSH in range on current levothyroxine dose.",
      codes: [ [ "E03.9", "Hypothyroidism, unspecified", "Cause not specified in note." ] ],
      return_note: "Please add the long-term drug therapy code.",
      revise: [ "Z79.899", "Other long term (current) drug therapy", "Ongoing levothyroxine." ] }
  ].freeze

  def self.reset!
    ActiveRecord::Base.connection.execute("TRUNCATE review_versions, review_codes, review_charts RESTART IDENTITY CASCADE")
    CHARTS.each_with_index { |spec, index| build(spec, index) }
  end

  def self.build(spec, index)
    chart = nil
    as(CODER) do
      chart = Review::Chart.create!(patient_initials: spec[:initials], specialty: spec[:specialty], encounter_summary: spec[:summary])
      spec[:codes].each_with_index do |(code, description, rationale), position|
        chart.codes.create!(code:, description:, rationale:, position: position + 1)
      end
    end
    return backdate(chart, index) if spec[:target] == :draft

    as(CODER) { chart.submit! }

    if spec[:return_note]
      as(REVIEWER) do
        chart.return_note = spec[:return_note]
        chart.return_to_coder!
      end
      if spec[:revise]
        as(CODER) do
          code, description, rationale = spec[:revise]
          chart.codes.create!(code:, description:, rationale:, position: chart.codes.count + 1)
          chart.submit!
        end
      end
    end

    as(REVIEWER) { chart.approve! } if spec[:target] == :approved
    backdate(chart, index)
  end

  def self.as(whodunnit, &) = PaperTrail.request(whodunnit:, &)

  # Space a chart's versions ~7 minutes apart over the last few hours, so the
  # timeline always reads as the recent past whenever the demo is reset.
  def self.backdate(chart, index)
    start = 4.hours.ago + (index * 25).minutes
    Review::Version.where(chart_id: chart.id).order(:id).each_with_index do |version, step|
      version.update_columns(created_at: start + (step * 7).minutes)
    end
  end
end
