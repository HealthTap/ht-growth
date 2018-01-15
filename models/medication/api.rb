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
                clinicalDrugForms
                conditionsTreated
                contraindicatedConditions
                drugClasses
                drugForms
                drugInteractions
                drugSchedule
                drugScheduleDescription
                formsWithUsage
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
    fields = %w[alcoholInteraction
                brandNames
                conditionsTreated
                drugForms
                drugSchedule
                name
                pregnancyCategory]
    api_values(fields, contents)
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
    when 'clinicalDrugForms'
      data['clinical_drug_dose_form']&.map { |i| rxcui_lookups[i.to_i] } || []
    when 'conditionsTreated'
      data['ndfrt_conditions']&.values&.reduce(:+)&.map(&:downcase) || []
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
      comp_data['interaction comparison'] = compare_interactions(self, top_comp)
      comp_data
    when 'type'
      # data['concept_type']&.tr('_', ' ')
      data['active_compound_group'].to_i == rxcui ? 'generic drug' : 'brand'
    when 'warning'
      data.dig('free_text', 'warnings_and_precautions')
    end
  end

  # Helpers for get_value ^^
  def drug_forms(data)
    forms = (data['branded_dose_form'] || []) +
            (data['clinical_drug_dose_form'] || [])
    forms.slice(0, 5)
  end

  def severe_interactions
    medication_interactions.where(severity: 'severe')
                           .pluck(:interacts_with_rxcui)
  end

  # Filters top n non-severe interactions
  def normal_interactions(n = 5)
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
