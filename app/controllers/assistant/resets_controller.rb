module Assistant
  # Puts the demo back to its seeded state: golden set reloaded, prompt v1,
  # no runs.
  class ResetsController < ApplicationController
    def create
      Seeds.load_all!
      Seeds.for("assistant").reset!
      redirect_to assistant_eval_runs_path, notice: "Assistant demo reset: golden set reloaded, prompt back to v1, runs cleared."
    end
  end
end
