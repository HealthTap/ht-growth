module Healthtap
  # Interface with ht-webapp12 api
  class Api
    API_KEY = 'bhmBagy36ltABc2OmeNF'
    API_BASE = 'https://www.healthtap.com/api/v2'

    # TODO: Use custom api endpoint (/api/v2/guest_questions) instead
    def self.questions(ids)
      id_types = ids.map { |id| "UserQuestion_#{id}" }.join(',')
      uri = URI("#{API_BASE}/public_fetch.json?key=#{API_KEY}&representation=basic&id_types=#{id_types}")
      response = Oj.load(Net::HTTP.get(uri))
    end
  end
end
