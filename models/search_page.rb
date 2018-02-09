# Functional equavalent of the old logged-out topic pages
# Is centered aroudn a search string and is populated
# with preset related questions
# Very important for SEO so be careful when modifying!!!
class SearchPage < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
  validates :name, length: { maximum: 200 }

  has_many :related_questions, as: :has_questions
  has_many :related_searches, as: :has_searches

  HTML_SITEMAP_FLAGS = %w[good].freeze
  LINKED_TO_FLAGS = %w[good].freeze # Whether we actively link to this page
  HTML_PATH = '/health/topics'.freeze

  def in_html_sitemap?
    HTML_SITEMAP_FLAGS.include?(seo_flag)
  end

  def linked_to?
    LINKED_TO_FLAGS.include?(seo_flag) && pathname
  end

  def to_s
    name
  end

  def pathname
    "#{HTML_PATH}/#{to_param}"
  end

  def as_json
    question_ids = related_questions.pluck(:question_id)
    {
      'name' => name,
      'url' => pathname,
      'userQuestions' => Healthtap::Api.questions(question_ids),
      'relatedSearches' => related_searches.map(&:as_json),
      'topic' => topic,
      'definition' => definition
    }
  end
end
