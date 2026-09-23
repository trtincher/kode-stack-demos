module Assistant
  # The Evals tab: the prompt editor, the run history, and one run's detail.
  class EvalRunsController < ApplicationController
    rate_limit to: 6, within: 1.hour, only: :create, by: -> { "all" }, with: -> { rate_limited }

    def index
      @prompt = PromptVersion.current!
      @adapter = ModelAdapter.current
      @case_count = EvalCase.count
      @active_run = EvalRun.active.recent.first
      @runs = EvalRun.recent.includes(:prompt_version).limit(15)
    end

    def show
      @run = EvalRun.includes(:prompt_version, eval_results: :eval_case).find(params[:id])
    end

    def create
      if (active = EvalRun.active.first)
        redirect_to assistant_eval_run_path(active), notice: "A run is already in progress; one at a time keeps model costs bounded."
      elsif EvalCase.none?
        redirect_to assistant_eval_runs_path, notice: "The golden set is empty. Reset the demo to load it."
      else
        run = EvalRun.create!(prompt_version: PromptVersion.current!, adapter: ModelAdapter.current.label, cases_total: EvalCase.count)
        RunEvalsJob.perform_later(run.id)
        redirect_to assistant_eval_run_path(run)
      end
    end

    private

    def rate_limited
      render turbo_stream: turbo_stream.update("assistant_flash", partial: "assistant/flash",
        locals: { message: "The demo runs at most 6 eval runs an hour across all visitors. Try again later." }),
        status: :too_many_requests
    end
  end
end
