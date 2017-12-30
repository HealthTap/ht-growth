require File.expand_path '../../spec_helper.rb', __FILE__

describe RelatedSearch do
  describe 'create related question' do
    m = Medication.create name: 'test_medication', rxcui: 0
    it 'should validate has_searches' do
      rq = RelatedSearch.create(search_string: 'foo', flag: 'foo', rank: 1)
      expect(rq.valid?).to be false
    end
    it 'should validate question_id' do
      rq = RelatedSearch.create(has_searches: m, flag: 'foo', rank: 1)
      expect(rq.valid?).to be false
    end
    it 'should validate flag' do
      rq = RelatedSearch.create(has_searches: m,
                                search_string: 'foo',
                                rank: 1)
      expect(rq.valid?).to be false
    end
    it 'should validate rank' do
      rq = RelatedSearch.create(has_searches: m,
                                search_string: 'foo',
                                flag: 'foo')
      expect(rq.valid?).to be false
    end
    it 'should have correct url' do
      rq = RelatedSearch.create(has_searches: m,
                                search_string: 'foo',
                                flag: 'foo')
      expect(rq.url).to eq '/topics/foo'
    end
  end
  describe 'medication has related questions' do
    m = Medication.create name: 'test_medication', rxcui: 0
    it 'should order by rank' do
      RelatedSearch.create(has_searches: m,
                           search_string: 'hi',
                           flag: 'foo',
                           rank: 5)
      RelatedSearch.create(has_searches: m,
                           search_string: 'hello',
                           flag: 'foo',
                           rank: 1)
      expect(m.related_searches.last.search_string).to eq 'hi'
    end
  end
end
