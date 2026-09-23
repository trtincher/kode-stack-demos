class CreateAssistantEvalResults < ActiveRecord::Migration[8.1]
  def change
    create_table :assistant_eval_results do |t|
      t.references :eval_run, null: false, foreign_key: { to_table: :assistant_eval_runs, on_delete: :cascade }
      t.references :eval_case, null: false, foreign_key: { to_table: :assistant_eval_cases, on_delete: :cascade }
      t.string :expected_codes, array: true, null: false, default: []
      t.string :got_codes, array: true, null: false, default: []
      t.jsonb :suggestions, null: false, default: []
      t.decimal :precision, precision: 5, scale: 4, null: false
      t.decimal :recall, precision: 5, scale: 4, null: false
      t.decimal :f1, precision: 5, scale: 4, null: false
      t.boolean :passed, null: false, default: false
      t.string :error
      t.timestamps
    end
    add_index :assistant_eval_results, %i[eval_run_id eval_case_id], unique: true
  end
end
