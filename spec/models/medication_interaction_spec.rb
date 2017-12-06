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
  end
  describe 'upload and read medication interactions' do
    it 'should not interact with itself' do
      m = Medication.create name: 'test_medication', rxcui: 0
      interactions_data = [
        { 'interacts_with_rxcui' => '1', 'ingredient_rxcui' => '0',
          'severity' => 'severe' },
        { 'interacts_with_rxcui' => '2', 'ingredient_rxcui' => '0',
          'severity' => 'normal' },
        { 'interacts_with_rxcui' => '3', 'ingredient_rxcui' => '0',
          'severity' => 'normal', 'rank' => '0' }
      ]
      RxcuiLookup.create(rxcui: 0, name: 'test_medication')
      RxcuiLookup.create(rxcui: 1, name: 'test_medication_1')
      RxcuiLookup.create(rxcui: 2, name: 'test_medication_2')
      RxcuiLookup.create(rxcui: 3, name: 'test_medication_3')
      m.reset_interactions(interactions_data)
      expect(m.medication_interactions.length).to eq(3)
      int_hash = m.top_interactions_hash
      expect(int_hash[0]['interacts_with']).to eq('test_medication_1')
      expect(int_hash[1]['interacts_with']).to eq('test_medication_3')
      expect(int_hash[2]['interacts_with']).to eq('test_medication_2')
    end
  end
end
