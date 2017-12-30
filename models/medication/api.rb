# Get values for api response
class Medication < ActiveRecord::Base

  def all_values
    fields = %w[alcoholInteraction
                availableGeneric
                brandNames
                conditionsTreated
                contraindicatedConditions
                drugClasses
                drugForms
                drugInteractions
                formsWithUsage
                isPrescribable
                name
                genericStrengths
                overdoseWarning
                pregnancyCategory
                severeDrugInteractions
                synonyms
                topComparisonDrug
                type]
    api_values(fields, contents)
  end

  def api_values(values, data)
    lookups = generate_lookups(data)
    resp = {}
    values.each { |v| resp[v] = api_value(v, data, lookups) }
    resp
  end

  # Mapping from data to api value
  def api_value(val, data, rxcui_lookups)
    case val
    when 'alcoholInteraction'
      data['alcohol_interaction']
    when 'availableGeneric'
      data['available_generic']
    when 'brandNames'
      data['brand_names']&.map { |i| rxcui_lookups[i.to_i] } || []
    when 'conditionsTreated'
      data.dig('ndfrt_conditions', 'additionalProperties') || []
    when 'contraindicatedConditions'
      data.dig('contraindicated_conditions', 'additionalProperties') || []
    when 'drugClasses'
      data['drug_classes'] || []
    when 'drugForms'
      drug_forms(data)&.map { |i| rxcui_lookups[i.to_i] }
    when 'drugInteractions'
      normal_interactions.map(&:interacts_with_name) || []
    when 'formsWithUsage'
      drug_forms(data).map do |i|
        m = Medication.find_by_rxcui(i)
        next unless m
        {
          'name' => m.name,
          'usage' => m.contents.dig('free_text', 'dosage_instructions')
        }
      end.compact
    when 'isPrescribable'
      data['can_be_prescribed']
    when 'name'
      data['name']
    when 'genericStrengths'
      data['available_strengths'] || []
    when 'overdoseWarning'
      data.dig('free_text', 'overdose')
    when 'pregnancyCategory'
      data['pregnancy_category']
    when 'severeDrugInteractions'
      severe_interactions.map(&:interacts_with_name) || []
    when 'synonyms'
      data['similar_drugs'] || []
    when 'topComparisonDrug' # TODO: top comparison drug
      nil
    when 'type'
      data['concept_type']&.tr('_', ' ')
    end
  end

  # Helpers for get_value ^^
  def drug_forms(data)
    (data['branded_dose_form'] || []) + (data['clinical_drug_dose_form'] || [])
  end

  def severe_interactions
    medication_interactions.where(severity: 'severe')
  end

  # Filters top n non-severe interactions
  def normal_interactions(n = 5)
    medication_interactions.where("severity is null or severity != 'severe'").order(MedicationInteraction.order_query).limit(n)
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
