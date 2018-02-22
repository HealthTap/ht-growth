require File.expand_path '../../spec_helper.rb', __FILE__

describe HtmlSitemap do
  describe 'create and access sitemap' do
    sitemap_json = {
      'analgesics' => {
        'display_name' => 'analgesics',
        'popular' => {
          'display_name' => 'popular',
          'tree_leaves' => [1, 2]
        }
      },
      'anti-inflammatory' => {
        'display_name' => 'anti-inflammatory',
        'tree_leaves' => [3, 4, 5]
      }
    }
    sitemap = HtmlSitemap.create(name: 'drug-classes',
                                 display_name: 'drugs',
                                 model: Medication)
    sitemap.upload_sitemap(sitemap_json)
    it 'gets top level' do
      expected_links =
        [
          { 'url' => '/health/drug-classes/analgesics/popular',
            'display_name' => 'popular' }
        ]
      expect(sitemap.sitemap(%w[analgesics])).to eq(expected_links)
    end
    it 'gets bottom level' do
      Medication.create rxcui: 1, name: 'Water'
      Medication.create rxcui: 2, name: 'Alcohol'
      expected_links = [
        { 'url' => '/health/drugs/alcohol', 'display_name' => 'Alcohol' },
        { 'url' => '/health/drugs/water', 'display_name' => 'Water' }
      ]
      expect(sitemap.sitemap(%w[analgesics popular])).to eq(expected_links)
    end
  end
end
