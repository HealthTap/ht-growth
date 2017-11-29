require File.expand_path '../../spec_helper.rb', __FILE__

describe Document do
  describe 'write a medication document' do
    it 'should write and read to dynamo' do
      d = Document.create name: 'fluoxetine', table_name: 'medications'
      d.overwrite(brand_name: 'prozac')
      expect(d.contents['brand_name']).to eq('prozac')
    end
    it 'should read nested attributes' do
      d = Document.create name: 'fluoxetine', table_name: 'medications'
      interaction = 'May experience depression when taking prozac with advil'
      new_json = {
        'brand_name' => 'prozac',
        'interactions' => {
          'advil' => interaction
        }
      }
      d.overwrite(new_json)
      expect(d.contents['interactions']['advil']).to eq(interaction)
    end
  end
  describe 'edit a medication document' do
    it 'should set an attribute' do
      d = Document.create name: 'fluoxetine', table_name: 'medications'
      new_json = {
        'brand_name' => 'nozac'
      }
      d.overwrite(new_json)
      d.update_content('brand_name', 'prozac')
      expect(d.contents['brand_name']).to eq('prozac')
    end
    it 'should set a nested attribute' do
      d = Document.create name: 'fluoxetine', table_name: 'medications'
      new_json = {
        'brand_name' => 'nozac',
        'dose_forms' => [
          { 'form' => 'tablet', 'dosage' => '50ml' },
          { 'form' => 'tablet', 'dosage' => '20ml' },
          { 'form' => 'cream', 'dosage' => '20ml' }
        ]
      }
      d.overwrite(new_json)
      d.update_content('dose_forms[1].dosage', '30ml')
      expect(d.contents['dose_forms'][1]['dosage']).to eq('30ml')
    end
    it 'should add to an array' do
      d = Document.create name: 'fluoxetine', table_name: 'medications'
      new_json = {
        'brand_name' => 'nozac',
        'dose_forms' => [
          { 'form' => 'tablet', 'dosage' => '50ml' },
          { 'form' => 'tablet', 'dosage' => '20ml' },
          { 'form' => 'cream', 'dosage' => '20ml' }
        ]
      }
      d.overwrite(new_json)
      new_dose_form = { 'form' => 'syrup', 'dosage' => '20ml' }
      d.add_to_array('dose_forms', new_dose_form)
      expect(d.contents['dose_forms'][-1]['form']).to eq('syrup')
    end
    it 'should remove from an array' do
      d = Document.create name: 'fluoxetine', table_name: 'medications'
      new_json = {
        'brand_name' => 'nozac',
        'dose_forms' => [
          { 'form' => 'tablet', 'dosage' => '50ml' },
          { 'form' => 'tablet', 'dosage' => '20ml' },
          { 'form' => 'cream', 'dosage' => '20ml' }
        ]
      }
      d.overwrite(new_json)
      to_remove = { 'form' => 'tablet', 'dosage' => '50ml' }
      d.delete_from_array('dose_forms', to_remove)
      expect(d.contents['dose_forms'].count).to eq(2)
    end
  end
end
