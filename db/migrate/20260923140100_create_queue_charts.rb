class CreateQueueCharts < ActiveRecord::Migration[8.1]
  def change
    create_table :queue_charts do |t|
      t.string :reference, null: false
      t.string :specialty, null: false
      t.string :chart_type, null: false
      t.text :summary, null: false
      t.integer :payout_cents, null: false
      t.datetime :due_at, null: false
      t.string :status, null: false, default: "available"
      t.references :coder, foreign_key: { to_table: :queue_coders }
      t.datetime :claimed_at
      t.datetime :claim_expires_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :queue_charts, :reference, unique: true
    add_index :queue_charts, [ :status, :due_at ]
    add_index :queue_charts, :claim_expires_at, where: "status = 'claimed'", name: "index_queue_charts_on_open_claim_expiry"

    add_check_constraint :queue_charts, "status IN ('available', 'claimed', 'done')", name: "queue_charts_status_known"
    # A chart has a coder exactly when it is not available: the claim state
    # cannot drift from the status column.
    add_check_constraint :queue_charts, "(status = 'available') = (coder_id IS NULL)", name: "queue_charts_coder_matches_status"
    add_check_constraint :queue_charts, "status <> 'claimed' OR claim_expires_at IS NOT NULL", name: "queue_charts_claim_has_expiry"
  end
end
