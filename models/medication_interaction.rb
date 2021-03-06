# Interaction between two medications
# Taken from rxnorm
class MedicationInteraction < ActiveRecord::Base
  validates_presence_of :interacts_with_rxcui, :ingredient_rxcui
  validates_uniqueness_of :interacts_with_rxcui,
                          uniqueness: {
                            scope: %i[ingredient_rxcui medication_id]
                          }
  validate :cannot_interact_with_itself

  belongs_to :medication

  def cannot_interact_with_itself
    return if interacts_with_rxcui != ingredient_rxcui
    errors.add(:interacts_with_rxcui, "can't be the same as ingredient_rxcui")
  end

end
