# Public demo: anyone may put the queue back to its seeded state.
class ChartQueue::ResetsController < ChartQueue::BaseController
  def create
    Seeds.load_all!
    Seeds.for("queue").reset!
    Turbo::StreamsChannel.broadcast_replace_to ChartQueue::Chart::STREAM, target: "queue_columns",
      partial: "chart_queue/board/columns", locals: { columns: ChartQueue::Chart.by_column, counts: ChartQueue::Chart.counts }

    redirect_to queue_root_path(as: current_coder&.slug), notice: "Queue reset to #{ChartQueue::Chart.count} synthetic charts."
  end
end
