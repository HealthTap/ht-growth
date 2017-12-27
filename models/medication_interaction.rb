# Interaction between two medications
# Taken from rxnorm
class MedicationInteraction < ActiveRecord::Base
  validates_presence_of :interacts_with_rxcui, :ingredient_rxcui
  validates_uniqueness_of :interacts_with_rxcui,
                          uniqueness: {
                            scope: %i[ingredient_rxcui medication_id]
                          }
  validate :cannot_interact_with_itself

  belongs_to :medication_interaction_group

  SEVERITY_ORDER = %w[severe normal]

  def cannot_interact_with_itself
    return if interacts_with_rxcui != ingredient_rxcui
    errors.add(:interacts_with_rxcui, "can't be the same as ingredient_rxcui")
  end

  def to_hash
    {
      'ingredient' => ingredient_name,
      'interacts_with' => interacts_with_name,
      'severity' => severity
    }
  end

  # If we have too many interactions, we need a way to prioritize them,
  # First order by severity, then by custom set rank, then everything else
  def self.order_query
    ordered_fields = SEVERITY_ORDER.map { |e| "'#{e}'" }.join(', ')
    "FIELD (severity, #{ordered_fields}), -rank DESC"
  end
end
