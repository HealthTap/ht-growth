require File.expand_path '../../spec_helper.rb', __FILE__

describe Medication do
  describe 'create medication' do
    it 'should validate name' do
      m = Medication.create
      expect(m.valid?).to be false
    end

    it 'should have a name' do
      m = Medication.create name: 'fluoxetine'
      expect(m.valid?).to be true
      expect(m.name).to eq('fluoxetine')
    end

    it 'should have a document associated with it' do
      m = Medication.create name: 'fluoxetine'
      expect(m.document.name).to eq('fluoxetine')
    end
  end
end
