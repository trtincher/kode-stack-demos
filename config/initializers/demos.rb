# The demo registry. The home page, the shared nav, db/seeds.rb, and
# ResetDemoDataJob all read this list, so a demo appears everywhere by being
# listed here. Each demo owns its own route namespace (e.g. `namespace :queue`)
# and its own seed file at db/seeds/<key>.rb; nothing here registers routes.
DEMOS = [
  {
    key: "queue",
    path: "/queue",
    title: "Chart queue",
    blurb: "Coders claim synthetic charts from a live shared queue; row locks keep two tabs from grabbing the same chart, and a job releases claims that blow their SLA.",
    stack: "Turbo Streams · Action Cable · FOR UPDATE SKIP LOCKED · Sidekiq"
  },
  {
    key: "review",
    path: "/review",
    title: "Review workflow",
    blurb: "A coded chart moves from draft to review to returned or approved, with inline edits, a full audit timeline, and keyboard shortcuts for the reviewer.",
    stack: "aasm · Turbo Frames · PaperTrail · Stimulus shortcuts"
  },
  {
    key: "assistant",
    path: "/assistant",
    title: "Coding assistant + evals",
    blurb: "A background job sends a synthetic encounter note to a model and streams suggested codes back with confidence, and an Evals tab scores it against a golden set.",
    stack: "Sidekiq · Turbo Streams · model adapter · golden-set evals"
  }
].freeze

# Namespace for the per-demo seed modules. Each demo adds db/seeds/<key>.rb:
#
#   module Seeds::Queue
#     def self.reset!
#       # delete and recreate this demo's synthetic rows
#     end
#   end
module Seeds
  # db/seeds/*.rb sit outside the autoload paths, so load them explicitly.
  # `load` (not `require`) so a changed seed file is picked up in development.
  def self.load_all!
    Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |file| load file }
  end

  # The seed module for a demo key, or nil when the demo has not shipped one.
  # Looked up on Seeds directly: a plain "Seeds::Queue".safe_constantize would
  # fall through to Ruby's top-level ::Queue (Thread::Queue) when no seed file
  # defines Seeds::Queue.
  def self.for(key)
    name = key.to_s.camelize
    return unless const_defined?(name, false)

    mod = const_get(name, false)
    mod if mod.respond_to?(:reset!)
  end

  # Resets every registered demo that ships a seed module; returns the keys reset.
  def self.reset_all!
    load_all!
    DEMOS.filter_map do |demo|
      seed = self.for(demo[:key]) or next
      seed.reset!
      demo[:key]
    end
  end
end
