# Simple lookup for rxcui to medication name
class RxcuiLookup < ActiveRecord::Base
  validates_presence_of :name

  # Returns top n ranked by rxcui rank where 1 is highest, 100,000 is lower
  # and nil is the lowest
  def self.top_concepts(rxcuis, n)
    RxcuiLookup.where(rxcui: rxcuis).order('-rank DESC').limit(n).pluck(:rxcui)
  end
end
