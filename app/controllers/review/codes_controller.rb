# Inline code edits. Each code row is a Turbo Frame: edit swaps the row for a
# form, update swaps it back and also prepends the new audit entry to the
# chart's timeline and announces the save in the live region.
class Review::CodesController < Review::BaseController
  before_action :set_code

  def show
    render partial: "review/codes/code", locals: row_locals
  end

  def edit
    return render(partial: "review/codes/code", locals: row_locals) unless editable?
  end

  def update
    unless editable?
      @alert = "The #{current_role.label.downcase} can't edit codes while the chart is #{@chart.state_label.downcase}."
      return render :refused, formats: :turbo_stream
    end

    if @code.update(code_params)
      @entry = Review::TimelineEntry.new(@code.versions.last)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to review_chart_path(@chart), flash: { review_notice: "Saved #{@code.code}." } }
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_code
    @chart = Review::Chart.find(params[:chart_id])
    @code = @chart.codes.find(params[:id])
  end

  def editable? = @chart.editable_by?(current_role)

  def row_locals = { code: @code, chart: @chart, editable: editable? }

  def code_params
    params.expect(review_code: %i[code description rationale])
  end
end
