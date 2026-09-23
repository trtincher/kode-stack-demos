# A synthetic medical coder. Identified by slug so a pick survives a reseed.
class ChartQueue::Coder < ApplicationRecord
  self.table_name = "queue_coders"

  has_many :charts, class_name: "ChartQueue::Chart", dependent: :nullify

  validates :slug, :name, presence: true

  def to_param = slug
  def first_name = name.split.first
end
