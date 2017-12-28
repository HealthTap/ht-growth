# Get values for api response
class Medication < ActiveRecord::Base

  def get_section(section)
    case section
    when 'overview'
      resp = get_values(%w(availableGeneric brandNames conditionsTreated), contents)
    end
  end

  def get_values(values, data)
    lookups = generate_lookups(data)
    resp = {}
    values.each { |v| resp[v] = get_value(v, data, lookups) }
    resp
  end

  def get_value(val, data, rxcui_lookups)
    case val
    when 'availableGeneric'
      data['available_generic']
    when 'brandNames'
      data['brand_names'].map { |bn| rxcui_lookups[bn.to_i] }
    when 'conditionsTreated'
      data['ndfrt_conditions'] & ['additionalProperties']
    when 'drugClasses'
      data['drug_classes'].map { |bn| rxcui_lookups[bn.to_i] }
    when 'drugForms'
      data['branded_dose_form'] + data['clinical_drug_dose_form']
    when 'name'
      data['name']
    when 'genericStrengths'
      data['available_strengths']
    when 'synonyms'
      data['similar_drugs']
    when 'type'
      data['concept_type']
    end
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
