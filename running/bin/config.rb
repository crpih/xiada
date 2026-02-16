require "active_support/core_ext/string/inflections"

require_relative "database_wrapper"
require_relative "proper_nouns"

# spanish_eslora profile
require_relative "../spanish_eslora/lemmatizer"
require_relative "../spanish_eslora/pruning_system"
require_relative
require_relative "../spanish_eslora/enclitics/rule_matching"
require_relative "../spanish_eslora/enclitics/validate_decomposition"
require_relative "../spanish_eslora/enclitics/filter_tags"

# galician_eslora profile
require_relative "../galician_eslora/lemmatizer"
require_relative "../galician_eslora/pruning_system"
require_relative "../galician_eslora/enclitics/rule_matching"
require_relative "../galician_eslora/enclitics/validate_decomposition"
require_relative "../galician_eslora/enclitics/filter_tags"

# galician_xiada profile
require_relative "../galician_xiada/lemmatizer"
require_relative "../galician_xiada/pruning_system"
require_relative "../galician_xiada/enclitics/rule_matching"
require_relative "../galician_xiada/enclitics/validate_decomposition"
require_relative "../galician_xiada/enclitics/filter_tags"

# galician_xiada_oral profile
require_relative "../galician_xiada_oral/lemmatizer"
require_relative "../galician_xiada_oral/pruning_system"
require_relative "../galician_xiada_oral/enclitics/rule_matching"
require_relative "../galician_xiada_oral/enclitics/validate_decomposition"
require_relative "../galician_xiada_oral/enclitics/filter_tags"

# galician_palmed profile
require_relative "../galician_palmed/lemmatizer"
require_relative "../galician_palmed/pruning_system"
require_relative "../galician_palmed/enclitics/rule_matching"
require_relative "../galician_palmed/enclitics/validate_decomposition"
require_relative "../galician_palmed/enclitics/filter_tags"

module Config
  class Tagger
    attr_reader :profile, :database, :seseo, :only_lexicon, :force_proper_nouns
    attr_reader :proper_nouns_processor, :dw, :lemmatizer, :pruning_system, :main_lexicon
    attr_reader :enclitics_rule_matching, :enclitics_filter_tags, :enclitics_validate_decomposition

    def self.from_env
      new(profile: ENV["XIADA_PROFILE"],
          database: ENV["XIADA_DATABASE"],
          only_lexicon: ENV["XIADA_ONLY_LEXICON"] == "true",
          force_proper_nouns: ENV["XIADA_FORCE_PROPER_NOUNS"] == "true")
    end

    def initialize(
      profile:,
      database:,
      only_lexicon: false,
      force_proper_nouns: false
    )
      @profile = profile
      @database = database
      @only_lexicon = only_lexicon
      @dw = DatabaseWrapper.new(self) # Warning: circular dependency
      @main_lexicon = ::ProperNouns.parse_main_lexicon("training/lexicons/#{profile}/lexicon_principal.txt")

      profile_module = profile.camelize
      proper_nouns_config = "#{profile_module}::ProperNouns".constantize
      proper_nouns_file = "training/lexicons/#{profile}/lexicon_propios.txt"
      ambiguous_proper_nouns_file = "training/lexicons/#{profile}/lexicon_titulos.txt"
      @proper_nouns_processor =
        if File.exist?(proper_nouns_file)
          ::ProperNouns.new(
            proper_nouns_config,
            @main_lexicon,
            ProperNouns.parse_literals_file(proper_nouns_file),
            File.exist?(ambiguous_proper_nouns_file) ? ProperNouns.parse_literals_file(ambiguous_proper_nouns_file) : [],
            CSV.read("training/lexicons/#{profile}/proper_nouns_links.txt", col_sep: "\t").map(&:first),
            CSV.read("training/lexicons/#{profile}/proper_nouns_candidate_tags.txt", col_sep: "\t").map(&:first),
            acronyms: @dw.get_acronyms,
            abbreviations: @dw.get_abbreviations,
            force_proper_nouns:
          )
        else
          nil
        end

      @lemmatizer = "#{profile_module}::Lemmatizer".constantize.new(self)
      @pruning_system = "#{profile_module}::PruningSystem".constantize.new
      @enclitics_rule_matching = "#{profile_module}::Enclitics::RuleMatching".constantize.new
      @enclitics_filter_tags = "#{profile_module}::Enclitics::FilterTags".constantize.new
      @enclitics_validate_decomposition = "#{profile_module}::Enclitics::ValidateDecomposition".constantize.new
    end

    def force_proper_nouns = @proper_nouns_processor&.force_proper_nouns || false # Use false in case of nil
  end

  # Document tagging configuration created for each request
  class Document
    attr_reader :seseo, :gheada

    def self.from_env = new(seseo: ENV["XIADA_SESEO"] == "true", gheada: ENV["XIADA_GHEADA"] == "true")

    def initialize(seseo:, gheada:)
      @seseo = seseo
      @gheada = gheada
    end
  end

  class ProperNouns
    def initialize(tag_has_gender:, tag_has_number:, generic_proper_noun_tag:)
      @tag_has_gender = tag_has_gender
      @tag_has_number = tag_has_number
      @generic_proper_noun_tag = generic_proper_noun_tag
    end

    def tag_has_gender?(tag) = @tag_has_gender.(tag)
    def tag_has_number?(tag) = @tag_has_number.(tag)
    def generic_proper_noun_tag = @generic_proper_noun_tag
  end
end
