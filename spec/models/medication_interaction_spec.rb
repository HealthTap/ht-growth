require File.expand_path '../../spec_helper.rb', __FILE__

# Upload, sort medication interactions
describe MedicationInteraction do
  describe 'create' do
    it 'should not interact with itself' do
      mi = MedicationInteraction.create(interacts_with_rxcui: 0,
                                        ingredient_rxcui: 0,
                                        severity: 'bad')
      expect(mi.errors.count).to be(1)
    end
    it 'should create from hash' do
      interaction_json = {
        'ingredient_rxcui' => 1_000_112,
        'description' => '2/5',
        'interacts_with_rxcui' => 237_057
      }
      mi = MedicationInteraction.create(interaction_json)
      expect(mi.ingredient_rxcui).to eq(1_000_112)
    end
    it 'should reset interactions on medication' do
      m = Medication.create name: 'test_medication', rxcui: 0
      pairs = [
        {
          'ingredient_rxcui' => 1_000_112,
          'description' => '2/5',
          'interacts_with_rxcui' => 237_057
        },
        {
          'ingredient_rxcui' => 1_000_111,
          'description' => 'Dr. Pelle says to not take these together',
          'interacts_with_rxcui' => 237_052
        }
      ]
      m.reset_interactions(pairs)
      expect(m.medication_interactions.length).to eq(2)
    end
  end
end
