class CreateDocuments < ActiveRecord::Migration[5.1]
  def change
    create_table :documents, primary_key: :document_key do |t|
      t.string :table_name
    end
  end
end
