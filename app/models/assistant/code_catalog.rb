module Assistant
  # A made-up coding system. The codes and descriptions are synthetic and do
  # not map to ICD-10 or CPT. `keywords` are used only by the Fake adapter;
  # the real model reads the code list and descriptions.
  module CodeCatalog
    Entry = Data.define(:code, :description, :keywords)

    ENTRIES = [
      Entry.new("KX-C101", "Synthetic essential hypertension", [ "hypertension", "high blood pressure" ]),
      Entry.new("KX-C102", "Synthetic hyperlipidemia", [ "hyperlipidemia", "high cholesterol" ]),
      Entry.new("KX-C110", "Synthetic chest pain, unspecified", [ "chest pain" ]),
      Entry.new("KX-C120", "Synthetic atrial fibrillation", [ "atrial fibrillation", "afib" ]),
      Entry.new("KX-M201", "Synthetic type 2 diabetes without complication", [ "type 2 diabetes", "diabetes mellitus" ]),
      Entry.new("KX-M210", "Synthetic hypothyroidism", [ "hypothyroidism" ]),
      Entry.new("KX-M220", "Synthetic obesity", [ "obesity" ]),
      Entry.new("KX-R301", "Synthetic acute bronchitis", [ "bronchitis" ]),
      Entry.new("KX-R302", "Synthetic acute pharyngitis", [ "pharyngitis", "sore throat" ]),
      Entry.new("KX-R304", "Synthetic asthma, mild intermittent", [ "asthma", "wheezing" ]),
      Entry.new("KX-R305", "Synthetic community-acquired pneumonia", [ "pneumonia" ]),
      Entry.new("KX-G401", "Synthetic migraine without aura", [ "migraine" ]),
      Entry.new("KX-G402", "Synthetic tension-type headache", [ "tension headache", "tension-type headache" ]),
      Entry.new("KX-N501", "Synthetic urinary tract infection", [ "urinary tract infection", "dysuria" ]),
      Entry.new("KX-K601", "Synthetic gastroesophageal reflux", [ "reflux", "heartburn" ]),
      Entry.new("KX-K602", "Synthetic acute gastroenteritis", [ "gastroenteritis", "vomiting and diarrhea" ]),
      Entry.new("KX-S701", "Synthetic sprain of ankle", [ "ankle sprain", "sprained" ]),
      Entry.new("KX-S702", "Synthetic low back pain", [ "low back pain" ]),
      Entry.new("KX-S703", "Synthetic laceration of hand", [ "laceration" ]),
      Entry.new("KX-D801", "Synthetic major depressive episode", [ "depression", "depressed mood" ]),
      Entry.new("KX-D802", "Synthetic generalized anxiety", [ "anxiety", "anxious" ]),
      Entry.new("KX-D803", "Synthetic insomnia", [ "insomnia", "trouble sleeping" ]),
      Entry.new("KX-Z901", "Synthetic tobacco use", [ "tobacco", "cigarettes", "smokes" ]),
      Entry.new("KX-Z902", "Synthetic annual preventive visit", [ "annual physical", "wellness visit" ])
    ].freeze

    BY_CODE = ENTRIES.index_by(&:code).freeze

    def self.codes = BY_CODE.keys
    def self.find(code) = BY_CODE[code]
    def self.description_for(code) = BY_CODE[code]&.description

    # The code list as the model sees it, appended to the system prompt.
    def self.to_prompt
      ENTRIES.map { |entry| "#{entry.code}: #{entry.description}" }.join("\n")
    end
  end
end
