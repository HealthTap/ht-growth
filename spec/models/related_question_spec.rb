require File.expand_path '../../spec_helper.rb', __FILE__

describe RelatedQuestion do
  describe 'create related question' do
    m = Medication.create name: 'test_medication', rxcui: 0
    it 'should validate has_questions' do
      rq = RelatedQuestion.create(question_id: 1, flag: 'foo', rank: 1)
      expect(rq.valid?).to be false
    end
    it 'should validate question_id' do
      rq = RelatedQuestion.create(has_questions: m, flag: 'foo', rank: 1)
      expect(rq.valid?).to be false
    end
    it 'should validate flag' do
      rq = RelatedQuestion.create(has_questions: m, question_id: 1, rank: 1)
      expect(rq.valid?).to be false
    end
    it 'should validate rank' do
      rq = RelatedQuestion.create(has_questions: m, question_id: 1, flag: 'foo')
      expect(rq.valid?).to be false
    end
  end
  describe 'medication has related questions' do
    m = Medication.create name: 'test_medication', rxcui: 0
    it 'should order by rank' do
      RelatedQuestion.create(has_questions: m,
                             question_id: 9,
                             flag: 'foo',
                             rank: 5)
      RelatedQuestion.create(has_questions: m,
                             question_id: 100,
                             flag: 'foo',
                             rank: 1)
      expect(m.related_questions.last.question_id).to eq 9
    end
  end
end
