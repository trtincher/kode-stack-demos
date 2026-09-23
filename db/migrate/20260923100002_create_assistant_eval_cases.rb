class CreateAssistantEvalCases < ActiveRecord::Migration[8.1]
  def change
    create_table :assistant_eval_cases do |t|
      t.string :key, null: false
      t.string :title, null: false
      t.text :note, null: false
      t.string :expected_codes, array: true, null: false, default: []
      t.boolean :showcase, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :assistant_eval_cases, :key, unique: true
  end
end
