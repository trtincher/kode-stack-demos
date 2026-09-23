# Synthetic data only. Each demo ships db/seeds/<key>.rb defining
# Seeds::<Key>.reset! (see config/initializers/demos.rb); this loads every
# seed file and resets each registered demo. Idempotent: run it any time.
Seeds.reset_all!.each { |key| puts "seeded #{key}" }
