# Get values for api response
class Medication < ActiveRecord::Base

  def all_values
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
                formsWithUsage
                hasOTC
                ingredientIn
                isPrescribable
                name
                generic
                genericStrengths
                overdoseWarning
                photo
                pregnancyCategory
                pregnancyCategoryDescription
                severeDrugInteractions
                synonyms
                topComparisonDrug
                type
                warning]
    api_vaues = api_values(fields, data)
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

  def compare_interactions(a,b)
  end

  def api_values(values, data)
    lookups = generate_lookups(data)
    resp = {}
    values.each { |v| resp[v] = api_value(v, data, lookups) }
    resp
  end

  # Mapping from dynamo document to api value
  def api_value(val, data, rxcui_lookups)
    case val
    when 'alcoholInteraction'
      data['alcohol_interaction']
    when 'availableGeneric'
      data['available_generic']
    when 'brandNames'
      RxcuiLookup.top_concepts(data['brand_names'], 5) || []
    when 'brandedDoseForms'
      data['branded_dose_form']&.map { |i| rxcui_lookups[i.to_i] } || []
    when 'clinicalDoseForms'
      data['clinical_drug_dose_form']&.map { |i| rxcui_lookups[i.to_i] } || []
    when 'conditionsTreated'
      conditions(data)
    when 'contraindicatedConditions'
      data['contraindicated_conditions']&.values&.reduce(:+)&.map(&:downcase) || []
    when 'drugClasses'
      data['drug_classes'] || []
    when 'drugForms'
      drug_forms(data).map { |i| rxcui_lookups[i.to_i] }
    when 'drugInteractions'
      data['normal_interactions'] || []
    when 'drugSchedule'
      data['addiction_drug_schedule']
    when 'drugScheduleDescription'
      Description.substance_schedule(data['addiction_drug_schedule'])
    when 'formsWithUsage'
      Medication.where(rxcui: drug_forms(data)).map do |m|
        {
          'name' => m.name,
          'usage' => m.contents.dig('free_text', 'dosage_instructions')
        }
      end
    when 'hasOTC'
      data['availiability'] == 'No prescription needed'
    when 'ingredientIn'
      puts 'ingredients'
      puts data['ingredients'] # TODO: Need what is a member of
      data['multiple_ingredients']&.map { |i| rxcui_lookups[i.to_i] } || []
    when 'isPrescribable'
      data['can_be_prescribed']
    when 'name'
      data['name']
    when 'generic'
      rxcui_lookups[data['active_compound_group'].to_i]
    when 'genericStrengths'
      data['available_strengths'] || []
    when 'overdoseWarning'
      data.dig('free_text', 'overdose')
    when 'photo'
      image_url
    when 'pregnancyCategory'
      data['pregnancy_category']
    when 'pregnancyCategoryDescription'
      Description.pregnancy(data['pregnancy_category'])
    when 'severeDrugInteractions'
      data['severe_interactions'].map do |interaction|
        rxcui_lookups[interaction.interacts_with_rxcui.to_i]
      end || []
    when 'synonyms'
      canonical_name = data['canonical_name']&.downcase
      canonical_name == name.downcase ? [] : [data['canonical_name']]
    when 'topComparisonDrug' # TODO: top comparison drug
      top_comp = Medication.find_by_rxcui(data['similar_drugs']&.slice(0).dig('rxcui').to_i)
      comp_data = top_comp&.comparison_values || {}
      comparison_interactions = (comp_data['severeDrugInteractions'] + comp_data['drugInteractions']).to_set
      main_interactions = (api_value('severeDrugInteractions', data, rxcui_lookups) + api_value('drugInteractions', data, rxcui_lookups)).to_set
      comp_data['sharedInteractions'] = (comparison_interactions.intersection(main_interactions)).to_a
      comp_data['comparisonInteractionsUnique'] = (comparison_interactions - main_interactions).to_a
      comp_data['mainInteractionsUnique'] = (main_interactions - comparison_interactions).to_a
      comparison_conditions = comp_data['conditionsTreated'].to_set
      main_conditions = conditions(data).to_set
      comp_data['sharedConditions'] = (comparison_conditions.intersection(main_conditions)).to_a
      comp_data['comparisonConditionsUnique'] = (comparison_conditions - main_conditions).to_a
      comp_data['mainConditionsUnique'] = (main_conditions - comparison_conditions).to_a
      comp_data
    when 'type'
      # data['concept_type']&.tr('_', ' ')
      data['active_compound_group'].to_i == rxcui ? 'generic drug' : 'brand'
    when 'warning'
      data.dig('free_text', 'warnings_and_precautions')
    end
  end

  def conditions(data)
    data['ndfrt_conditions']&.values&.reduce(:+)&.map(&:downcase) || []
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
  def normal_interactions(n = 15)
    medication_interactions.where("severity is null or severity != 'severe'")
                           .joins('inner join rxcui_lookups
                                   on rxcui_lookups.rxcui =
                                   medication_interactions.
                                   interacts_with_rxcui')
                           .order('-medication_interactions.rank desc,
                                   -rxcui_lookups.rank desc')
                           .limit(n)
                           .pluck(:name)
  end

  # Preload the lookup table for rxcui mappings
  # Do pre-processing of names here
  # For example, if the name for rxcui=1 is too long, apply trimming rules
  def generate_lookups(data)
    rxcuis = []
    gather_rxcui = lambda { |h|
      if h.is_a?(Numeric)
        rxcuis << h.to_i
      elsif h.is_a?(Array)
        h.each { |el| gather_rxcui.call(el) }
      elsif h.is_a?(Hash)
        h.each_value { |v| gather_rxcui.call(v) }
      end
    }
    gather_rxcui.call(data)
    lookup_table = {}
    lookups = RxcuiLookup.where(rxcui: rxcuis).select(:rxcui, :name)
    lookups.each { |l| lookup_table[l.rxcui] = l.name }
    lookup_table
  end
end
