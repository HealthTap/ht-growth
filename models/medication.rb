# Medication data for medication pages
# Should have a document with static content
# Also includes meta data around medication i.e. seo rules, experiments, etc
class Medication < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates_presence_of :name, :rxcui
  validates_uniqueness_of :name, :rxcui
  validates :name, length: { maximum: 200 }
  # TODO: decide on max name length (we really don't need to be storing
  # super long medication names if we never display them anywhere)
  # TODO: rules for trimming for displaying as url or title...

  after_create :find_or_create_document
  belongs_to :document, foreign_key: :rxcui

  has_many :medication_interactions
  has_many :related_questions, as: :has_questions
  has_many :related_searches, as: :has_searches

  DOCUMENT_TABLE_NAME = 'medications'.freeze
  S3_FOLDER = 'medications'.freeze
  HTML_PATH = '/health/drugs'.freeze

  # SEO flag should be used to encode behavior for SEO that the
  # medication generates
  # Some examples are which sitemap the medication page belongs to,
  # whether it should appear on an html sitemap, xml sitemap,
  # whether to noindex the page, etc.
  HTML_SITEMAP_FLAGS = %w[good].freeze
  LINKED_TO_FLAGS = %w[good].freeze # Whether we actively link to this page

  after_initialize :default_name

  def in_html_sitemap?
    HTML_SITEMAP_FLAGS.include?(seo_flag)
  end

  def linked_to?
    LINKED_TO_FLAGS.include?(seo_flag) && pathname
  end

  def pathname
    "#{HTML_PATH}/#{to_param}"
  end

  def to_s
    name
  end

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

  # Creates interactions from hash
  def create_interactions(interaction_pairs)
    interactions = interaction_pairs.map do |pair|
      pair['medication_id'] = id
      MedicationInteraction.new(pair)
    end
    MedicationInteraction.import interactions
    medication_interactions << interactions
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
    upload_related(data)
    data.delete('drug_interactions')
    data.delete('related_questions')
    data.delete('related_searches')
    document.overwrite(data)
  end

  def upload_data_nosql_only(data)
    Medication.validate_json(data)
    document.overwrite(data)
  end

  def upload_related(data)
    related_questions.destroy_all
    question_objects = []
    data['related_questions'].each do |section, questions|
      questions.each_with_index do |q, i|
        question_objects << RelatedQuestion.new(rank: i, flag: section,
                                                has_questions_id: id,
                                                question_id: q)
      end
    end
    RelatedQuestion.import question_objects
    related_questions << question_objects
    related_searches.destroy_all
    search_objects = []
    data['related_searches'].each do |section, searches|
      searches.each_with_index do |s, i|
        search_objects << RelatedSearch.new(rank: i, flag: section,
                                            has_searches_id: id,
                                            search_string: s)
      end
    end
    RelatedSearch.import search_objects
    related_searches << search_objects
  end

  # We want to overwrite interactions if we get them wrong...
  # Expects an array of interaction groups
  def reset_interactions(interaction_pairs)
    medication_interactions.destroy_all
    create_interactions(interaction_pairs)
  end

  # API get methods

  # All relevant content we need for a medication page
  def section(section)
    resp = all_values(section)
    resp['breadcrumbs'] = HtmlSitemap.find_by_name('drug-classes')
                                       &.breadcrumbs([resp['drugClasses'][0]].compact) || []
    resp
  end
end
