module Assistant
  # Sends one visitor note to the model adapter and streams the suggestions
  # back to the page that asked, over `assistant_request_<uuid>`.
  #
  # The note lives only in this job's arguments. Arguments are kept out of the
  # log, and every failure is caught and reported to the page instead of
  # re-raised, so the note never sits in Sidekiq's retry or dead set.
  class SuggestCodesJob < ApplicationJob
    queue_as :default
    self.log_arguments = false

    def perform(request_id:, note:)
      stream = "assistant_request_#{request_id}"
      prompt = PromptVersion.current!
      adapter = ModelAdapter.current
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      broadcast_status(stream, :running, "Running prompt v#{prompt.version} on #{adapter.label}…")
      suggestions = adapter.suggest(note: note, prompt: prompt.body)

      suggestions.each do |suggestion|
        Turbo::StreamsChannel.broadcast_append_to(
          stream, target: "assistant_suggestions",
          partial: "assistant/suggestions/suggestion", locals: { suggestion: suggestion }
        )
      end

      # Appends are the streaming feel; this replace is the truth. If the page
      # missed an append (the subscription landed late), the terminal list
      # heals it.
      Turbo::StreamsChannel.broadcast_replace_to(
        stream, target: "assistant_suggestions",
        partial: "assistant/suggestions/list", locals: { suggestions: suggestions }
      )

      elapsed = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      summary = suggestions.empty? ? "No catalog codes found in this note" : "#{suggestions.size} #{"code".pluralize(suggestions.size)} suggested"
      broadcast_status(stream, :done, "#{summary} · prompt v#{prompt.version} · #{adapter.label} · #{elapsed} ms")
    rescue AdapterError => e
      broadcast_status(stream, :failed, e.message)
    rescue StandardError => e
      Rails.logger.error("[assistant] suggest failed: #{e.class}")
      broadcast_status(stream, :failed, "Something went wrong running the assistant.") if stream
    end

    private

    def broadcast_status(stream, state, message)
      Turbo::StreamsChannel.broadcast_replace_to(
        stream, target: "assistant_status",
        partial: "assistant/suggestions/status", locals: { state: state, message: message }
      )
    end
  end
end
