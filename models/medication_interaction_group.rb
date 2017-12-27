# Group of interactions from a single source with comment(s)
class MedicationInteractionGroup < ActiveRecord::Base
  validates_presence_of :source
  belongs_to :medication
  has_many :medication_interactions, dependent: :destroy

  def self.from_hash(json)
    group = MedicationInteractionGroup.create(
      source: json['source'],
      comment: json['comment']
    )
    pairs = json['interaction_pairs'] || []
    medication_interactions = pairs.map do |p|
      p['medication_interaction_group_id'] = group.id
      MedicationInteraction.new(p)
    end
    MedicationInteraction.import medication_interactions
    group
  end
end
