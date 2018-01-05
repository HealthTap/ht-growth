# Medical description lookups
# For now, used for pregnancy category and drug schedule descriptions
# Could be used for disclaimers, drug class descriptions,
# text associated with an abbreviation
class Description < ActiveRecord::Base
  validates_presence_of :name, :category, :value
  validates_uniqueness_of :name,
                          uniqueness: {
                            scope: %i[category]
                          }

  PREGNANCY_CATEGORY = 'Pregnancy Category'.freeze
  SUBSTANCE_SCHEDULE_CATEGORY = 'Controlled Substance Schedule'.freeze

  def self.pregnancy(category)
    where(category: PREGNANCY_CATEGORY, name: category).first&.value
  end

  def self.substance_schedule(schedule)
    where(category: SUBSTANCE_SCHEDULE_CATEGORY, name: schedule).first&.value
  end
end
