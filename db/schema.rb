# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171228184229) do

  create_table "document_edits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "edit_type"
    t.string "attribute_path"
    t.string "value"
    t.bigint "document_id"
    t.index ["document_id"], name: "index_document_edits_on_document_id"
  end

  create_table "documents", primary_key: "document_key", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "table_name"
  end

  create_table "medication_interaction_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "source"
    t.text "comment"
    t.bigint "medication_id"
    t.index ["medication_id"], name: "index_medication_interaction_groups_on_medication_id"
  end

  create_table "medication_interactions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "interacts_with_rxcui"
    t.integer "ingredient_rxcui"
    t.integer "rank"
    t.string "severity"
    t.text "description"
    t.text "ingredient_name"
    t.string "ingredient_url"
    t.text "interacts_with_name"
    t.string "interacts_with_url"
    t.bigint "medication_interaction_group_id"
    t.index ["medication_interaction_group_id"], name: "index_medication_interactions_on_medication_interaction_group_id"
  end

  create_table "medications", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "rxcui"
    t.string "name"
    t.string "seo_flag"
    t.string "experiment_group"
    t.bigint "document_id"
    t.boolean "has_image"
    t.datetime "updated_at"
    t.index ["document_id"], name: "index_medications_on_document_id"
  end

  create_table "rxcui_lookups", primary_key: "rxcui", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text "name"
  end

end
