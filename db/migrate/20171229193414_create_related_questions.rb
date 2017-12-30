class CreateRelatedQuestions < ActiveRecord::Migration[5.1]
  def change
    create_table :related_questions do |t|
      t.integer :question_id
      t.string :flag
      t.integer :rank
      t.references :has_questions,
                   polymorphic: true,
                   index: {
                     name: 'index_rq_on_hq_type_and_hq_id' # Abbreviate name
                   }
    end
  end
end
