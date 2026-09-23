module Assistant
  # Saving the prompt form creates the next version; old versions stay put so
  # earlier runs keep pointing at the text they ran.
  class PromptVersionsController < ApplicationController
    def create
      body = params[:body].to_s.strip
      current = PromptVersion.current!

      if body == current.body
        redirect_to assistant_eval_runs_path, notice: "The prompt is unchanged, so it is still v#{current.version}."
      else
        version = PromptVersion.create_next!(body)
        redirect_to assistant_eval_runs_path, notice: "Saved prompt v#{version.version}. Run the evals to see how it scores."
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_to assistant_eval_runs_path, notice: "Prompt not saved: #{e.record.errors.full_messages.to_sentence}."
    end
  end
end
