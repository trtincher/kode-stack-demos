class CreateQueueCoders < ActiveRecord::Migration[8.1]
  def change
    create_table :queue_coders do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :color, null: false, default: "slate"
      t.timestamps
    end
    add_index :queue_coders, :slug, unique: true
  end
end
