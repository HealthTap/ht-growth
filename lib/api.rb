module Healthtap
  # Interface with ht-webapp12 api
  class Api
    API_KEY = 'bhmBagy36ltABc2OmeNF'.freeze
    API_BASE = 'https://www.healthtap.com/api/v2'.freeze
    SEARCH_API_BASE = 'https://search-staging.healthtap.com/api/v003'.freeze

    def self.num_lives_saved
      k = 'num-lives-saved'
      lives_saved = Cache.read_static(k)
      return lives_saved if lives_saved
      uri = URI("#{API_BASE}/lives_saved_answers_served.json?key=#{API_KEY}")
      lives_saved = Oj.load(Net::HTTP.get(uri))['num_lives_saved']
      Cache.write_static(k, lives_saved)
      lives_saved
    end

    def self.num_answers_served
      k = 'num-answers-served'
      answers_served = Cache.read_static(k)
      return answers_served if answers_served
      uri = URI("#{API_BASE}/lives_saved_answers_served.json?key=#{API_KEY}")
      answers_served = Oj.load(Net::HTTP.get(uri))['num_answers_served']
      Cache.write_static(k, answers_served)
      answers_served
    end

    def self.num_doctors
      k = 'num-doctors'
      doctors = Cache.read_static(k)
      return doctors if doctors
      uri = URI("#{API_BASE}/registered_doctors.json?key=#{API_KEY}")
      doctors = Oj.load(Net::HTTP.get(uri))['num_docs']
      Cache.write_static(k, doctors)
      doctors
    end

    def self.questions(ids)
      response = []
      id_params = ''
      ids.each do |id|
        question = Cache.read_question(id)
        if question
          response.push(question)
        else
          id_params += "&ids[]=#{id}"
        end
      end
      unless id_params.empty?
        uri = URI("#{API_BASE}/user_questions/guest?key=#{API_KEY}#{id_params}")
        res = Oj.load(Net::HTTP.get(uri))
        new_questions = res['result'] ? res['objects'] : []
        new_questions.each { |q| Cache.write_question(q['id'], q) }
        response += new_questions
      end
      questions_json(response)
    end

    def self.search_questions(search_string, per_page = 5)
      uri = URI("#{SEARCH_API_BASE}/questions?search_string=#{search_string}&key=#{API_KEY}&per_page=#{per_page}&nocache=1&page=1&v=2&action=search&controller=api%2Fv2%2Fapi&format=json&use_elastic_search=true&ui_locale=en")
      response = Oj.load(Net::HTTP.get(uri))
      ids = response['question_ids']
      questions(ids)
    end

    # Convert expert from ht-webapp12 api format to nextweb format
    # Expects: name photo url specialty practice_duration
    # and medical_school (array of { school, year })
    def self.expert_json(expert)
      return unless %w[name photo url].all? { |s| expert.key? s }
      medical_school = expert['medical_school']&.max_by do |s|
        s['year']&.to_i || 0
      end&.fetch('school')
      {
        'name' => expert['name'],
        'photo' => expert['photo'],
        'url' => expert['url'],
        'specialty' => expert['specialty'],
        'practiceDuration' => expert['practice_duration'],
        'medicalSchool' => medical_school # TODO trim long med schools?
      }
    end

    # Convert answer from ht-webapp12 api format to nextweb format
    # Expects: in_brief long_text created_at thanks_count agrees_count author
    def self.answer_json(answer)
      answer_body = answer['long_text']
      author = answer['author']
      return unless answer_body.present? && author.present?
      if answer['in_brief']
        delimiter = /[[:punct:]]/.match?(answer['in_brief'][-1]) ? ' ' : '. '
        answer_body = answer['in_brief'] + delimiter + answer_body
      end
      answer_body += '.' unless /[[:punct:]]/.match?(answer_body[-1])
      author = expert_json(author)
      return unless author
      {
        'answer' => answer_body, 'createdAt' => answer['created_at'],
        'thanksCount' => answer['thanks_count'] || 0,
        'agreesCount' => answer['agrees_count'] || 0,
        'author' => author
      }
    end

    # Convert question from ht-webapp12 api format to nextweb format
    def self.questions_json(questions)
      return [] unless questions
      questions.map do |q|
        next unless %w[id question url answers].all? { |s| q.key? s }
        q['answers'] = q['answers'].map do |a|
          answer_json(a)
        end.compact
        next if q['answers'].empty?
        q
      end.compact
    end
  end
end
