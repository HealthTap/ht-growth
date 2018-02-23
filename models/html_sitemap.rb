class HtmlSitemap < ActiveRecord::Base
  validates_presence_of :name, :display_name, :model
  validates_uniqueness_of :name
  serialize :model, Class

  belongs_to :concept_tree

  after_create :find_or_create_concept_tree

  KEY_PREFIX = 'sitemap-'.freeze
  SITEMAP_SUBDIRECTORY = 'health'.freeze

  def key
    "#{KEY_PREFIX}#{id}"
  end

  def find_or_create_concept_tree
    update_attribute(:concept_tree, ConceptTree.find_or_create_by(name: key))
  end

  def upload_sitemap(sitemap_json)
    concept_tree.overwrite_tree(sitemap_json)
  end

  # Array (ex. ['drug-classes', 'analgesics'])
  def sitemap(path = nil)
    raw_sitemap = path ? concept_tree.path(path) : concept_tree.tree
    if raw_sitemap.include?('tree_leaves')
      keys = raw_sitemap['tree_leaves']
      sitemap = model.where(model.primary_key => keys).map do |el|
        {
          'url' => el.pathname,
          'display_name' => el.to_s
        }
      end
    else
      sitemap = raw_sitemap.map do |k, v|
        next if k == 'display_name'
        {
          'url' => pathname(path, k),
          'display_name' => v['display_name'] || k
        }
      end.compact
    end
    sitemap.sort_by { |item| item['display_name'] }
  end

  # Returns URI of sitemap link
  def pathname(path, link)
    path_string = path&.length&.positive? ? '/' + path.join('/') : ''
    path_string = path_string.tr(' ', '-')
    "/#{SITEMAP_SUBDIRECTORY}/#{name}#{path_string}/#{link}"
  end

  def breadcrumbs(path)
    url = "/#{SITEMAP_SUBDIRECTORY}/#{name}"
    crumbs = [{
      'displayName' => 'Health',
      'url' => '/'
    }, {
      'displayName' => display_name,
      'url' => url
    }]
    path.each do |directory|
      url += "/#{directory.tr(' ', '-')}"
      crumbs.push(
        'displayName' => directory,
        'url' => url
      )
    end
    crumbs
  end
end
