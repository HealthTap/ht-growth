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
        'interacts_with_url' => 'http://www.drugbank.ca/interacts_with',
        'ingredient_rxcui' => 1_000_112,
        'description' => '2/5',
        'ingredient_url' => 'http://www.drugbank.ca/ingredient',
        'interacts_with_name' => 'Lepirudin',
        'ingredient_name' => 'Medroxyprogesterone acetate',
        'interacts_with_rxcui' => 237_057
      }
      mi = MedicationInteraction.create(interaction_json)
      expect(mi.ingredient_rxcui).to eq(1_000_112)
      expect(mi.ingredient_name).to eq('Medroxyprogesterone acetate')
    end
  end
end
