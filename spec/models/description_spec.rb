require File.expand_path '../../spec_helper.rb', __FILE__

describe Description do
  describe 'create description' do
    it 'should validate uniqueness of category/name pair' do
      d = Description.create(category: 'Pregnancy Category',
                             name: 'A',
                             value: 'Shoulda used protection')
      expect(d.valid?).to be true
      non_duplicate = Description.create(category: 'Pregnancy Category',
                                         name: 'B',
                                         value: 'Different description')
      expect(non_duplicate.valid?).to be true
      duplicate = Description.create(category: 'Pregnancy Category',
                                     name: 'A',
                                     value: 'Different description')
      expect(duplicate.valid?).to be false
    end
  end
  describe 'lookups' do
    it 'should lookup pregancy categories' do
      Description.create(category: 'Pregnancy Category',
                         name: 'A',
                         value: 'Shoulda used protection')
      v = Description.pregnancy('A')
      expect(v).to eq 'Shoulda used protection'
    end
    it 'should lookup drug schedules' do
      Description.create(category: 'Controlled Substance Schedule',
                         name: 'I',
                         value: "Don't do drugs, kids")
      v = Description.substance_schedule('I')
      expect(v).to eq "Don't do drugs, kids"
    end
  end
end
