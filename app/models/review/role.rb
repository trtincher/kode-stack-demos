# The two seeded people a visitor can act as. Synthetic names; the session
# holds only the key.
class Review::Role
  PEOPLE = {
    "coder" => { label: "Coder", name: "Sam Rivera" },
    "reviewer" => { label: "Reviewer", name: "Dana Okafor" }
  }.freeze
  DEFAULT = "reviewer".freeze

  attr_reader :key, :label, :name

  def self.all = PEOPLE.keys.map { |key| new(key) }

  def self.find(key)
    new(PEOPLE.key?(key.to_s) ? key.to_s : DEFAULT)
  end

  def initialize(key)
    @key = key
    @label = PEOPLE.fetch(key)[:label]
    @name = PEOPLE.fetch(key)[:name]
  end

  def coder? = key == "coder"
  def reviewer? = key == "reviewer"

  # Stored on every PaperTrail version, e.g. "Reviewer · Dana Okafor".
  def whodunnit = "#{label} · #{name}"

  def ==(other) = other.is_a?(Review::Role) && other.key == key
end
