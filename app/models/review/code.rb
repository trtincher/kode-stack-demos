# One assigned code on a chart (ICD-10-CM), with the coder's rationale.
class Review::Code < ApplicationRecord
  self.table_name = "review_codes"

  belongs_to :chart, class_name: "Review::Chart", inverse_of: :codes

  has_paper_trail versions: { class_name: "Review::Version" },
                  ignore: %i[updated_at],
                  meta: { chart_id: :chart_id }

  validates :code, :description, presence: true
  validates :code, format: { with: /\A[A-Z][0-9][0-9A-Z](\.[0-9A-Z]{1,4})?\z/, message: "must look like an ICD-10-CM code, e.g. E11.9" }
end
