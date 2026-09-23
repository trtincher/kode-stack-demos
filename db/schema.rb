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

  create_table "assistant_eval_cases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "expected_codes", default: [], null: false, array: true
    t.string "key", null: false
    t.text "note", null: false
    t.integer "position", default: 0, null: false
    t.boolean "showcase", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_assistant_eval_cases_on_key", unique: true
  end

  create_table "assistant_eval_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "error"
    t.bigint "eval_case_id", null: false
    t.bigint "eval_run_id", null: false
    t.string "expected_codes", default: [], null: false, array: true
    t.decimal "f1", precision: 5, scale: 4, null: false
    t.string "got_codes", default: [], null: false, array: true
    t.boolean "passed", default: false, null: false
    t.decimal "precision", precision: 5, scale: 4, null: false
    t.decimal "recall", precision: 5, scale: 4, null: false
    t.jsonb "suggestions", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["eval_case_id"], name: "index_assistant_eval_results_on_eval_case_id"
    t.index ["eval_run_id", "eval_case_id"], name: "index_assistant_eval_results_on_eval_run_id_and_eval_case_id", unique: true
    t.index ["eval_run_id"], name: "index_assistant_eval_results_on_eval_run_id"
  end

  create_table "assistant_eval_runs", force: :cascade do |t|
    t.string "adapter", null: false
    t.integer "cases_done", default: 0, null: false
    t.integer "cases_total", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "error"
    t.datetime "finished_at"
    t.decimal "mean_f1", precision: 5, scale: 4
    t.decimal "mean_precision", precision: 5, scale: 4
    t.decimal "mean_recall", precision: 5, scale: 4
    t.integer "passed_count", default: 0, null: false
    t.bigint "prompt_version_id", null: false
    t.datetime "started_at"
    t.string "status", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["prompt_version_id"], name: "index_assistant_eval_runs_on_prompt_version_id"
    t.index ["status"], name: "index_assistant_eval_runs_on_status"
  end

  create_table "assistant_prompt_versions", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "version", null: false
    t.index ["version"], name: "index_assistant_prompt_versions_on_version", unique: true
  end

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

  add_foreign_key "assistant_eval_results", "assistant_eval_cases", column: "eval_case_id", on_delete: :cascade
  add_foreign_key "assistant_eval_results", "assistant_eval_runs", column: "eval_run_id", on_delete: :cascade
  add_foreign_key "assistant_eval_runs", "assistant_prompt_versions", column: "prompt_version_id", on_delete: :cascade
  add_foreign_key "review_codes", "review_charts", column: "chart_id", on_delete: :cascade
end
