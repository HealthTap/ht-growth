require File.expand_path '../../spec_helper.rb', __FILE__

describe SearchPage do
  describe 'create medication' do
    it 'should validate name' do
      s = SearchPage.create
      expect(s.valid?).to be false
    end

    it 'should have a name' do
      s = SearchPage.create name: 'test_page'
      expect(s.valid?).to be true
      expect(s.name).to eq('test_page')
    end

    it 'should have a unique name' do
      s1 = SearchPage.create name: 'test_page'
      expect(s1.valid?).to be true
      s2 = SearchPage.create name: 'Test_Page'
      expect(s2.valid?).to be false
    end
  end
  describe 'json fields' do
    s = SearchPage.create(name: 'test_page',
                          topic: 'searchy search',
                          definition: 'find strings that are related')
    it 'should have related searches' do
      rs = RelatedSearch.create(has_searches: s,
                                search_string: 'dutch complex',
                                rank: 1)
      s.related_searches << rs
      s.as_json['relatedSearches'].should eq(
        [{ 'text' => 'Dutch complex', 'href' => '/topics/dutch-complex' }]
      )
    end

    it 'should have other fields' do
      json = s.as_json
      expect(json['name']).to eq('test_page')
      expect(json['topic']).to eq('searchy search')
      expect(json['definition']).to eq('find strings that are related')
    end
  end
end
