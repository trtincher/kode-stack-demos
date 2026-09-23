class CreateAssistantEvalRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :assistant_eval_runs do |t|
      t.references :prompt_version, null: false, foreign_key: { to_table: :assistant_prompt_versions, on_delete: :cascade }
      t.string :status, null: false, default: "queued"
      t.string :adapter, null: false
      t.integer :cases_total, null: false, default: 0
      t.integer :cases_done, null: false, default: 0
      t.integer :passed_count, null: false, default: 0
      t.decimal :mean_precision, precision: 5, scale: 4
      t.decimal :mean_recall, precision: 5, scale: 4
      t.decimal :mean_f1, precision: 5, scale: 4
      t.string :error
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end
    add_index :assistant_eval_runs, :status
  end
end
