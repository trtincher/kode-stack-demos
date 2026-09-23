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

ActiveRecord::Schema[8.1].define(version: 2026_09_23_120003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "review_charts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "encounter_summary", null: false
    t.string "patient_initials", null: false
    t.text "return_note"
    t.string "specialty", null: false
    t.string "state", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["state"], name: "index_review_charts_on_state"
  end

  create_table "review_codes", force: :cascade do |t|
    t.bigint "chart_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "position", null: false
    t.text "rationale"
    t.datetime "updated_at", null: false
    t.index ["chart_id"], name: "index_review_codes_on_chart_id"
  end

  create_table "review_versions", force: :cascade do |t|
    t.bigint "chart_id"
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.string "whodunnit"
    t.index ["chart_id"], name: "index_review_versions_on_chart_id"
    t.index ["item_type", "item_id"], name: "index_review_versions_on_item_type_and_item_id"
  end

  add_foreign_key "review_codes", "review_charts", column: "chart_id", on_delete: :cascade
end
