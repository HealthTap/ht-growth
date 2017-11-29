require File.expand_path '../../spec_helper.rb', __FILE__

describe DocumentEdit do
  describe 'replay changes' do
    it 'should replay changes over an overwrite' do
      d = Document.create name: 'fluoxetine', table_name: 'medications'
      d.overwrite(brand_name: 'advil')
      d.add_to_array('interactions', alcohol: "don't drink, kids")
      d.add_to_array('interactions', heroin: "don't do drugs, kids")
      d.update_content('brand_name', 'prozac')
      d.overwrite(brand_name: 'fluoxetine', interactions: [advil: 'none'])
      d.replay_edits
      expect(d.contents['brand_name']).to eq('prozac')
      first_interaction = d.contents['interactions'][1]
      expect(first_interaction).to eq('alcohol' => "don't drink, kids")
    end
  end
end
