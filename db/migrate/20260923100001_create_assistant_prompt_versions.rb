class CreateAssistantPromptVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :assistant_prompt_versions do |t|
      t.integer :version, null: false
      t.text :body, null: false
      t.timestamps
    end
    add_index :assistant_prompt_versions, :version, unique: true
  end
end
