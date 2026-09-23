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
  add_foreign_key "queue_charts", "queue_coders", column: "coder_id"
  add_foreign_key "review_codes", "review_charts", column: "chart_id", on_delete: :cascade
end
