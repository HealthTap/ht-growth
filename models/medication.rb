# Medication data for medication pages
# Should have a document with static content
# Also includes meta data around medication i.e. seo rules, experiments, etc
class Medication < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  belongs_to :document

  DOCUMENT_TABLE_NAME = 'medications'

  after_create :find_or_create_document

  def find_or_create_document
    self.document = Document.find_or_create_by(name: name) do |document|
      document.table_name = DOCUMENT_TABLE_NAME
    end
    save
  end

  def overview
    document.contents
  end
end
