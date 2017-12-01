# Medication data for medication pages
# Should have a document with static content
# Also includes meta data around medication i.e. seo rules, experiments, etc
class Medication < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
  belongs_to :document
  has_many :medication_interactions

  DOCUMENT_TABLE_NAME = 'medications'

  after_create :find_or_create_document

  def find_or_create_document
    self.document = Document.find_or_create_by(name: name) do |document|
      document.table_name = DOCUMENT_TABLE_NAME
    end
    save
  end

  # Different document types should have different rules for dynamo miss
  # All medications should have dynamo item associated with it
  # It is an error if we have a medication with no dynamo item
  def contents
    contents = document.contents
    raise 'Medication content missing' unless contents
    contents
  end

  # Call should be better optimized
  def top_interactions_hash
    top_interactions.map(&:to_hash)
  end

  # Filters top n interactions based on rules in medication interactions
  # TODO: Maybe ordering should be done in ruby rather than relying
  # on special mysql query
  def top_interactions(n = 5)
    medication_interactions.order(MedicationInteraction.order_query).limit(n)
  end

  # Creates interactions from hash
  def create_interactions(interactions_data)
    new_interactions = []
    interactions_data.each do |interaction|
      ingredient_rxcui = interaction['ingredient_rxcui'].to_i
      interacts_with_rxcui = interaction['interacts_with_rxcui'].to_i
      next unless RxcuiLookup.find_by_rxcui(interacts_with_rxcui)
      next unless RxcuiLookup.find_by_rxcui(ingredient_rxcui)
      mi = MedicationInteraction.new(interacts_with_rxcui: interacts_with_rxcui,
                                     ingredient_rxcui: ingredient_rxcui,
                                     severity: interaction['severity'],
                                     description: interaction['description'],
                                     medication: self)
      new_interactions << mi
    end
    import_data = MedicationInteraction.import new_interactions
    first_failed = import_data.failed_instances.slice(0, 4)
    "#{import_data.num_inserts} inserted, failures: #{first_failed}..."
  end

  # API post methods

  # Be careful! We want to overwrite interactions if we get them wrong...
  def reset_interactions(interactions_data)
    medication_interactions.destroy_all
    create_interactions(interactions_data)
  end

  # API get methods

  # All relevant content we need for a medication page
  def overview
    contents.merge('top_interactions' => top_interactions_hash)
  end
end
