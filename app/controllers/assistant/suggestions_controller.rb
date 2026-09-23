module Assistant
  # The Assistant tab. The page picks a request id when it renders and
  # subscribes to that stream up front, so no broadcast can beat it there.
  class SuggestionsController < ApplicationController
    UUID = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

    rate_limit to: 30, within: 1.hour, only: :create, with: -> { rate_limited }

    def new
      @request_id = SecureRandom.uuid
      @samples = EvalCase.showcase
      @prompt = PromptVersion.current!
      @adapter = ModelAdapter.current
    end

    def create
      request_id = params[:request_id].to_s
      note = params[:note].to_s.strip

      if !request_id.match?(UUID)
        render_status :failed, "This page is stale; reload it and try again.", :unprocessable_content
      elsif note.blank?
        render_status :failed, "Paste a note or pick a sample first.", :unprocessable_content
      elsif note.length > EvalCase::MAX_NOTE
        render_status :failed, "Notes are capped at #{EvalCase::MAX_NOTE} characters.", :unprocessable_content
      else
        SuggestCodesJob.perform_later(request_id: request_id, note: note)
        render turbo_stream: [
          turbo_stream.replace("assistant_status", partial: "assistant/suggestions/status",
            locals: { state: :queued, message: "Queued for a Sidekiq worker…" }),
          turbo_stream.update("assistant_suggestions", "")
        ]
      end
    end

    private

    def rate_limited
      render_status :rate_limited, "That's 30 requests from you this hour. The demo is capped to keep model costs sane; try again later.", :too_many_requests
    end

    def render_status(state, message, status)
      render turbo_stream: turbo_stream.replace("assistant_status", partial: "assistant/suggestions/status",
        locals: { state: state, message: message }), status: status
    end
  end
end
