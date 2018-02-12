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

ActiveRecord::Schema.define(version: 20180212221453) do

  create_table "concept_trees", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.integer "num_items"
    t.text "item_mapping"
  end

  create_table "descriptions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "category"
    t.text "value"
  end

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

  create_table "html_sitemaps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "model"
    t.bigint "concept_tree_id"
    t.index ["concept_tree_id"], name: "index_html_sitemaps_on_concept_tree_id"
  end

  create_table "medication_interactions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "interacts_with_rxcui"
    t.integer "ingredient_rxcui"
    t.integer "rank"
    t.string "severity"
    t.text "description"
    t.bigint "medication_id"
    t.index ["medication_id"], name: "index_medication_interactions_on_medication_id"
  end

  create_table "medications", primary_key: "rxcui", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "seo_flag"
    t.string "experiment_group"
    t.boolean "has_image"
    t.datetime "updated_at"
    t.string "slug"
    t.index ["slug"], name: "index_medications_on_slug", unique: true
  end

  create_table "related_questions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "question_id"
    t.string "flag"
    t.integer "rank"
    t.string "has_questions_type"
    t.bigint "has_questions_id"
    t.index ["has_questions_type", "has_questions_id"], name: "index_rq_on_hq_type_and_hq_id"
  end

  create_table "related_searches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "search_string"
    t.string "flag"
    t.integer "rank"
    t.string "has_searches_type"
    t.bigint "has_searches_id"
    t.string "slug"
    t.index ["has_searches_type", "has_searches_id"], name: "index_rs_on_hs_type_and_hs_id"
    t.index ["slug"], name: "index_related_searches_on_slug"
  end

  create_table "rxcui_lookups", primary_key: "rxcui", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text "name"
    t.integer "rank"
  end

  create_table "search_pages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "seo_flag"
    t.datetime "updated_at"
    t.string "slug"
    t.string "topic"
    t.text "definition"
    t.index ["slug"], name: "index_search_pages_on_slug", unique: true
  end

end
