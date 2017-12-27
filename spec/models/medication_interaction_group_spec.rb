require File.expand_path '../../spec_helper.rb', __FILE__

# Upload medication interaction groups
describe MedicationInteractionGroup do
  describe 'create group' do
    it 'should create from hash' do
      group_json = {
        'comment' => 'Resolved to medroxyprogesterone acetate',
        'source' => "Dr. Pelle's QTC",
        'interaction_pairs' => [{
          'severity' => 'srs',
          'interacts_with_url' => 'http://www.drugbank.ca/interacts_with',
          'ingredient_rxcui' => 1_000_112,
          'description' => '',
          'ingredient_url' => 'http://www.drugbank.ca/ingredient',
          'interacts_with_name' => 'Lepirudin',
          'ingredient_name' => 'Medroxyprogesterone acetate',
          'interacts_with_rxcui' => 237_057
        }]
      }
      group = MedicationInteractionGroup.from_hash(group_json)
      expect(group.comment).to eq('Resolved to medroxyprogesterone acetate')
      expect(group.source).to eq("Dr. Pelle's QTC")
      expect(group.medication_interactions.size).to eq(1)
    end
  end
  describe 'upload and read medication interaction groups' do
    it 'should reset interaction groups' do
      m = Medication.create name: 'test_medication', rxcui: 0
      groups_data = [
        {
          'comment' => 'Dr. Pelle believes this is not QTC',
          'source' => 'Dr. Pelle'
        },
        {
          'comment' => 'Very QTC',
          'source' => 'DrugBank'
        }
      ]
      m.reset_interactions(groups_data)
      expect(m.medication_interaction_groups.length).to eq(2)
    end
  end
end
