# Used in related questions modules, etc.
# For now, the only model that has questions is a medication
# Flag determines where it should be shown since medications
# have multiple sections.
# Question ids correspond to UserQuestion.id in ht-webapp12
class RelatedQuestion < ActiveRecord::Base
  validates_presence_of :question_id, :flag, :rank, :has_questions
  belongs_to :has_questions, polymorphic: true
  default_scope { order(rank: :asc) }
end
