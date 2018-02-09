# Used in related search modules, etc.
# For now, the only model that has searches is a medication
# Flag determines where it should be shown since medications
# have multiple sections.
# Search strings correspond to RelatedSearch.search_string in ht-webapp12
class RelatedSearch < ActiveRecord::Base
  extend FriendlyId
  friendly_id :search_string, use: :slugged

  validates_presence_of :search_string, :flag, :rank, :has_searches
  belongs_to :has_searches, polymorphic: true
  default_scope { order(rank: :asc) }

  def url
    "/topics/#{to_param}"
  end

  def as_json
    {
      'text' => search_string.capitalize,
      'href' => url
    }
  end
end
