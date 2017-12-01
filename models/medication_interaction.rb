# Interaction between two medications
# Taken from rxnorm
class MedicationInteraction < ActiveRecord::Base
  validates_presence_of :interacts_with_rxcui, :ingredient_rxcui, :severity
  validate :cannot_interact_with_itself

  belongs_to :medication

  SEVERITY_ORDER = %w(severe normal)

  def cannot_interact_with_itself
    return if interacts_with_rxcui != ingredient_rxcui
    errors.add(:interacts_with_rxcui, "can't be the same as ingredient_rxcui")
  end

  def to_hash
    {
      'ingredient' => RxcuiLookup.find_by_rxcui(ingredient_rxcui).name,
      'interacts_with' => RxcuiLookup.find_by_rxcui(interacts_with_rxcui).name,
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
