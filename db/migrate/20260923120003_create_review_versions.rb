# PaperTrail's versions table, renamed so it belongs to the review demo alone.
# chart_id is PaperTrail metadata: chart and code versions both carry it, so a
# chart's whole timeline is one indexed query.
class CreateReviewVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :review_versions do |t|
      t.string :item_type, null: false
      t.bigint :item_id, null: false
      t.string :event, null: false
      t.string :whodunnit
      t.jsonb :object
      t.jsonb :object_changes
      t.bigint :chart_id
      t.datetime :created_at
    end
    add_index :review_versions, %i[item_type item_id]
    add_index :review_versions, :chart_id
  end
end
