require File.expand_path '../../spec_helper.rb', __FILE__

describe Medication do
  describe 'create medication' do
    it 'should validate name' do
      m = Medication.create
      expect(m.valid?).to be false
    end

    it 'should have a name' do
      m = Medication.create name: 'test_medication', rxcui: 0
      expect(m.valid?).to be true
      expect(m.name).to eq('test_medication')
    end

    it 'should have a document associated with it' do
      m = Medication.create name: 'test_medication', rxcui: 0
      expect(m.document.document_key).to eq(0)
    end
  end
  describe 'get data for each content section' do
    it 'should have an overview' do
      m = Medication.create name: 'test_medication', rxcui: 0
      m.document.overwrite(brand_names: [0])
    end
  end
  describe 'upload image' do
    it 'should have a url' do
      m = Medication.create name: 'test_medication', rxcui: 3_000_000
      m.upload_image('spec/data/test_medication.png')
      expect(m.has_image).to be(true)
      expect(m.image_url).to eq('https://healthtap-guest.s3.amazonaws.com/medications/3000000')
    end
  end
  describe 'medications without images' do
    it 'should not have a url' do
      m = Medication.create name: 'test_medication', rxcui: 0
      expect(m.has_image).to be_falsey
      expect(m.image_url).to be_falsey
    end
  end
  describe 'upload data' do
    it 'should validate schema' do
      medication_data = Oj.load File.open('spec/data/sample_medication.json')
      Medication.validate_json(medication_data)
    end
    it 'should fail on invalid schema' do
      medication_data = Oj.load File.open('spec/data/sample_medication.json')
      medication_data['clinical_drug'] = ['not a number']
      err = JsonSchema::AggregateError
      expect { Medication.validate_json(medication_data) }.to raise_error(err)
    end
    it 'should upload sample data' do
      medication_data = Oj.load File.open('spec/data/sample_medication.json')
      rxcui = medication_data['rxcui']
      name = medication_data['name']
      m = Medication.find_or_create_by(rxcui: rxcui, name: name)
      m.upload_data(medication_data)
      expect(m.overview['name']).to eq('Acetaminophen')
    end
  end
end
