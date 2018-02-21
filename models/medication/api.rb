# Get values for api response
class Medication < ActiveRecord::Base

  def all_values(section = 'overview')
    data = contents.merge(
      'normal_interactions' => normal_interactions,
      'severe_interactions' => severe_interactions
    )
    fields = %w[alcoholInteraction
                availableGeneric
                brandNames
                brandedDoseForms
                clinicalDoseForms
                conditionsTreated
                contraindicatedConditions
                drugClasses
                drugForms
                drugInteractions
                drugSchedule
                drugScheduleDescription
                hasOTC
                ingredientIn
                isBrand
                isPrescribable
                name
                generic
                genericStrength
                overdoseWarning
                pathname
                photo
                pregnancyCategory
                pregnancyCategoryDescription
                severeDrugInteractions
                similarDrugs
                synonyms
                topComparisonDrug
                type
                url
                usage
                warning]
    api_values = api_values(fields, data)
    question_ids = related_questions.where(flag: section).pluck(:question_id)
    api_values['userQuestions'] = Healthtap::Api.questions(question_ids)
    api_values['relatedSearches'] = related_searches.where(flag: section).map(&:as_json)
    api_values['relatedQuestions'] = api_values['userQuestions'].map do |q|
      { 'text' => q['question'], 'href' => q['url'] }
    end
    api_values['hyperlinks'] = gather_hyperlinks(api_values)
    #api_values['titleTag'] =
    #api_values['metaDescription'] =
    api_values
  end

  # Data for comparison section between two drugs
  def comparison_values
    data = contents.merge(
      'normal_interactions' => normal_interactions,
      'severe_interactions' => severe_interactions
    )
    fields = %w[alcoholInteraction
                brandNames
                conditionsTreated
                drugForms
                drugInteractions
                drugSchedule
                name
                pregnancyCategory
                severeDrugInteractions]
    api_values(fields, data)
  end

  def api_values(values, data)
    resp = {}
    values.each { |v| resp[v] = api_value(v, data) }
    process_rxcuis(resp)
    resp
  end

  # Mapping from dynamo document to api value
  def api_value(val, data)
    case val
    when 'alcoholInteraction'
      data['alcohol_interaction']
    when 'availableGeneric'
      data['available_generic']
    when 'brandNames'
      return [] if data['brand_names'][0] == data['rxcui']
      RxcuiLookup.top_concepts(data['brand_names'], 5) || []
    when 'brandedDoseForms'
      data['branded_dose_form'] || []
    when 'clinicalDoseForms'
      data['clinical_drug_dose_form'] || []
    when 'conditionsTreated'
      conditions(data)
    when 'contraindicatedConditions'
      data['contraindicated_conditions']&.values&.reduce(:+)&.map(&:downcase)&.uniq || []
    when 'drugClasses'
      data['drug_classes'] || []
    when 'drugForms'
      drug_forms(data) || []
    when 'drugInteractions'
      data['normal_interactions']&.uniq || []
    when 'drugSchedule'
      data['addiction_drug_schedule']
    when 'drugScheduleDescription'
      Description.substance_schedule(data['addiction_drug_schedule'])
    when 'hasOTC'
      data['availiability'] == 'No prescription needed'
    when 'ingredientIn'
      data['multiple_ingredients'] || []
    when 'isBrand'
      data['concept_type'] == 'brand_name'
    when 'isPrescribable'
      data['can_be_prescribed']
    when 'name'
      data['name']
    when 'generic'
      data['active_compound_group']
    when 'genericStrength'
      data['available_strengths'][0]
    when 'overdoseWarning'
      data.dig('free_text', 'overdose')
    when 'pathname'
      pathname
    when 'photo'
      image_url
    when 'pregnancyCategory'
      data['pregnancy_category']
    when 'pregnancyCategoryDescription'
      Description.pregnancy(data['pregnancy_category'])
    when 'severeDrugInteractions'
      data['severe_interactions']&.uniq || []
    when 'similarDrugs'
      data['similar_drugs']&.map { |d| d['rxcui'] }&.compact || []
    when 'synonyms'
      canonical_name = data['canonical_name']&.downcase
      canonical_name.nil? || canonical_name == name.downcase ? [] : [data['canonical_name']]
    when 'topComparisonDrug' # TODO: top comparison drug
      top_comp = Medication.find_by_rxcui(data['similar_drugs']&.slice(0)&.dig('rxcui').to_i)
      comp_data = top_comp&.comparison_values || {}
      unless comp_data.empty?
        comparison_interactions = (comp_data['severeDrugInteractions'] + comp_data['drugInteractions']).to_set
        main_interactions = (api_value('severeDrugInteractions', data) + api_value('drugInteractions', data)).to_set
        comp_data['sharedInteractions'] = (comparison_interactions.intersection(main_interactions)).to_a
        comp_data['comparisonInteractionsUnique'] = (comparison_interactions - main_interactions).to_a
        comp_data['mainInteractionsUnique'] = (main_interactions - comparison_interactions).to_a
        comparison_conditions = comp_data['conditionsTreated'].to_set
        main_conditions = conditions(data).to_set
        comp_data['sharedConditions'] = (comparison_conditions.intersection(main_conditions)).to_a
        comp_data['comparisonConditionsUnique'] = (comparison_conditions - main_conditions).to_a
        comp_data['mainConditionsUnique'] = (main_conditions - comparison_conditions).to_a
      end
      comp_data
    when 'type'
      # data['concept_type']&.tr('_', ' ')
      data['active_compound_group'].to_i == rxcui ? 'generic drug' : 'branded drug'
    when 'url'
      pathname
    when 'usage'
      data.dig('free_text', 'dosage_instructions') || []
    when 'warning'
      data.dig('free_text', 'warnings_and_precautions')
    end
  end

  def conditions(data)
    data['ndfrt_conditions']&.values&.reduce(:+)&.map(&:downcase)&.uniq || []
  end

  # Helpers for get_value ^^
  def drug_forms(data)
    forms = (data['branded_dose_form'] || []) +
            (data['clinical_drug_dose_form'] || [])
    forms.slice(0, 10)
  end

  def severe_interactions
    medication_interactions.where(severity: 'severe')
                           .pluck(:interacts_with_rxcui)
  end

  # Filters top n non-severe interactions
  # The interaction pair has a rank based on importance, and the medication
  # has a rank based on popularity (traffic estimate)
  def normal_interactions(n = 15)
    medication_interactions.where("severity is null or severity != 'severe'")
                           .joins('inner join rxcui_lookups
                                   on rxcui_lookups.rxcui =
                                   medication_interactions.
                                   interacts_with_rxcui')
                           .order('medication_interactions.rank is null,
                                   medication_interactions.rank asc,
                                   rxcui_lookups.rank is null,
                                   rxcui_lookups.rank asc')
                           .limit(n)
                           .pluck(:rxcui)
  end

  # We want to tell client which medications can be hyperlinked to
  def gather_hyperlinks(data)
    rxcuis = data['rxcuis'] - [rxcui]
    hyperlinks = {}
    Medication.where(rxcui: rxcuis).each do |m|
      hyperlinks[m.name.downcase] = m.pathname if m.linked_to?
    end
    hyperlinks
  end

  # Replace rxcuis w/ names
  # Create hyperlink lookup for names which should be hyperlinked
  # All numerics assumed to be medication instances
  def process_rxcuis(data)
    rxcuis = []
    gather_rxcui = lambda do |h|
      if h.is_a?(Numeric)
        rxcuis << h.to_i
      elsif h.is_a?(Array)
        h.each { |el| gather_rxcui.call(el) }
      elsif h.is_a?(Hash)
        h.each_value { |v| gather_rxcui.call(v) }
      end
    end
    gather_rxcui.call(data)
    lookup_table = {}
    lookups = RxcuiLookup.where(rxcui: rxcuis).select(:rxcui, :name)
    lookups.each { |l| lookup_table[l.rxcui] = l.name }
    replace_rxcui = lambda do |h|
      if h.is_a?(Array)
        h.each_with_index do |el, i|
          if el.is_a?(Numeric)
            h[i] = lookup_table[el.to_i]
          else
            replace_rxcui.call(el)
          end
        end
      elsif h.is_a?(Hash)
        h.each do |k, v|
          next if k == 'rxcuis'
          if v.is_a?(Numeric)
            h[k] = lookup_table[v.to_i]
          else
            replace_rxcui.call(v)
          end
        end
      end
    end
    replace_rxcui.call(data)
    data['rxcuis'] = rxcuis
  end
end
