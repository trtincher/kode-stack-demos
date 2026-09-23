# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_23_140100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "queue_charts", force: :cascade do |t|
    t.string "chart_type", null: false
    t.datetime "claim_expires_at"
    t.datetime "claimed_at"
    t.bigint "coder_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "due_at", null: false
    t.integer "payout_cents", null: false
    t.string "reference", null: false
    t.string "specialty", null: false
    t.string "status", default: "available", null: false
    t.text "summary", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_expires_at"], name: "index_queue_charts_on_open_claim_expiry", where: "((status)::text = 'claimed'::text)"
    t.index ["coder_id"], name: "index_queue_charts_on_coder_id"
    t.index ["reference"], name: "index_queue_charts_on_reference", unique: true
    t.index ["status", "due_at"], name: "index_queue_charts_on_status_and_due_at"
    t.check_constraint "(status::text = 'available'::text) = (coder_id IS NULL)", name: "queue_charts_coder_matches_status"
    t.check_constraint "status::text <> 'claimed'::text OR claim_expires_at IS NOT NULL", name: "queue_charts_claim_has_expiry"
    t.check_constraint "status::text = ANY (ARRAY['available'::character varying, 'claimed'::character varying, 'done'::character varying]::text[])", name: "queue_charts_status_known"
  end

  create_table "queue_coders", force: :cascade do |t|
    t.string "color", default: "slate", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_queue_coders_on_slug", unique: true
  end

  add_foreign_key "queue_charts", "queue_coders", column: "coder_id"
end
