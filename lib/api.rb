module Healthtap
  # Interface with ht-webapp12 api
  class Api
    API_KEY = 'bhmBagy36ltABc2OmeNF'
    API_BASE = 'https://www.healthtap.com/api/v2'
    SEARCH_API_BASE = 'https://search-staging.healthtap.com/api/v003'

    def self.questions(ids)
      id_array = ids.map { |id| "ids[]=#{id}" }.join('&')
      uri_string = "#{API_BASE}/user_questions/guest?key=#{API_KEY}&#{id_array}"
      uri = URI(uri_string)
      response = Oj.load(Net::HTTP.get(uri))
      response
    end

    def self.search_questions(search_string, per_page = 3)
      uri = URI("#{SEARCH_API_BASE}/questions?search_string=#{search_string}&key=#{API_KEY}&per_page=#{per_page}&nocache=1&page=1&v=2&action=search&controller=api%2Fv2%2Fapi&format=json&use_elastic_search=true&ui_locale=en")
      response = Oj.load(Net::HTTP.get(uri))
      ids = response['question_ids']
      question_response = questions(ids)
      question_response['result'] ? question_response['objects'] : []
    end
  end
end
