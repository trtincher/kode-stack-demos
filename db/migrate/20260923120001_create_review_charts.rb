class CreateReviewCharts < ActiveRecord::Migration[8.1]
  def change
    create_table :review_charts do |t|
      t.string :patient_initials, null: false
      t.string :specialty, null: false
      t.text :encounter_summary, null: false
      t.string :state, null: false, default: "draft"
      t.text :return_note
      t.timestamps
    end
    add_index :review_charts, :state
  end
end
