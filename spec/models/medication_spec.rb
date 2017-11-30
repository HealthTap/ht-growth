require File.expand_path '../../spec_helper.rb', __FILE__

describe Medication do
  describe 'create medication' do
    it 'should validate name' do
      m = Medication.create
      expect(m.valid?).to be false
    end

    it 'should have a name' do
      m = Medication.create name: 'test_medication'
      expect(m.valid?).to be true
      expect(m.name).to eq('test_medication')
    end

    it 'should have a document associated with it' do
      m = Medication.create name: 'test_medication'
      expect(m.document.name).to eq('test_medication')
    end
  end
  describe 'get data for each content section' do
    it 'should have an overview' do
      m = Medication.create name: 'test_medication'
      m.document.overwrite(brand_name: 'prozac')
      expect(m.overview['brand_name']).to eq 'prozac'
    end
  end
end
