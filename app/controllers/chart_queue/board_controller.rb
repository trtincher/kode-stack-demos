class ChartQueue::BoardController < ChartQueue::BaseController
  def show
    @columns = ChartQueue::Chart.by_column
    @counts = ChartQueue::Chart.counts
  end

  # The polling fallback when Action Cable cannot connect: the same columns
  # block the page renders, as a Turbo Stream replace.
  def columns
    @columns = ChartQueue::Chart.by_column
    @counts = ChartQueue::Chart.counts
    render formats: :turbo_stream
  end
end
