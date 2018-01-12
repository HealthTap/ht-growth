require File.expand_path '../../spec_helper.rb', __FILE__

describe ConceptTree do
  describe 'upload concept tree' do
    org_chart = {
      'engineering' => {
        'backend' => ['Jerry Uejio', 'Dechao Qiu'],
        'search' => ['Marc Byrd', 'Alex Shoup']
      }
    }
    org_tree = ConceptTree.create(name: 'employee')
    org_tree.overwrite_tree(org_chart)
    it 'uploads' do
      expect(org_tree.tree).to eq(org_chart)
    end
    it 'overwrites' do
      new_org_chart = {
        'engineering' => {
          'backend' => ['Jerry Uejio', 'Dechao Qiu'],
          'search' => ['Marc Byrd', 'Alex Shoup']
        }
      }
      org_tree.overwrite_tree(new_org_chart)
      expect(org_tree.tree).to eq(new_org_chart)
    end
    it 'gets path' do
      backend_engineers = org_tree.path(%w[engineering backend])
      expect(backend_engineers).to eq ['Jerry Uejio', 'Dechao Qiu']
    end
  end
end
