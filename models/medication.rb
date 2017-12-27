# Medication data for medication pages
# Should have a document with static content
# Also includes meta data around medication i.e. seo rules, experiments, etc
class Medication < ActiveRecord::Base
  validates_presence_of :name, :rxcui
  validates_uniqueness_of :name, :rxcui
  belongs_to :document
  has_many :medication_interaction_groups
  has_many :medication_interactions, through: :medication_interaction_groups

  DOCUMENT_TABLE_NAME = 'medications'
  S3_FOLDER = 'medications'

  after_initialize :default_name
  after_create :find_or_create_document

  def default_name
    self.name ||= RxcuiLookup.find_by_rxcui(rxcui)&.name
  end

  def find_or_create_document
    self.document = Document.find_or_create_by(document_key:
                                               rxcui) do |document|
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
  def create_interaction_groups(groups_data)
    groups_data.each do |group_data|
      group = MedicationInteractionGroup.from_hash(group_data)
      medication_interaction_groups << group
    end
  end

  # Each medication may have one image of it
  # The bucket is shared between dev and production,
  # and the key format should be standardized as /medication/:rxcui
  def image_url
    return unless has_image
    bucket = App.settings.s3[:bucket]
    hostname = App.settings.s3[:hostname]
    "https://#{bucket}.#{hostname}/#{S3_FOLDER}/#{rxcui}"
  end

  # Right now the only way to set a medication image is via console
  def upload_image(filename)
    ImageUploader.write_image("#{S3_FOLDER}/#{rxcui}", filename)
    update_attribute(:has_image, true)
  end

  # API post methods

  def upload_data(data)
    Medication.validate_json(data)
    reset_interactions(data['drug_interactions'])
    data.delete('drug_interactions')
    document.overwrite(data)
  end

  # We want to overwrite interactions if we get them wrong...
  # Expects an array of interaction groups
  def reset_interactions(groups_data)
    medication_interaction_groups.destroy_all
    create_interaction_groups(groups_data)
  end

  # API get methods

  # All relevant content we need for a medication page
  def overview
    resp = contents.merge('top_interactions' => top_interactions_hash)
    resp.merge('user_questions' => Healthtap::Api.search_questions(name))
  end
end
