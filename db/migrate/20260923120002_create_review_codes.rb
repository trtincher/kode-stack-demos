class CreateReviewCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :review_codes do |t|
      t.references :chart, null: false, foreign_key: { to_table: :review_charts, on_delete: :cascade }
      t.string :code, null: false
      t.string :description, null: false
      t.text :rationale
      t.integer :position, null: false
      t.timestamps
    end
  end
end
