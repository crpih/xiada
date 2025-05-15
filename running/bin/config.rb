require "active_support/core_ext/string/inflections"

require_relative "database_wrapper"
require_relative "proper_nouns"

# spanish_eslora profile
require_relative "../spanish_eslora/lemmatizer"
require_relative "../spanish_eslora/pruning_system"
require_relative "../spanish_eslora/enclitics_rules"

# galician_eslora profile
require_relative "../galician_eslora/lemmatizer"
require_relative "../galician_eslora/pruning_system"
require_relative "../galician_eslora/enclitics_rules"

# galician_xiada profile
require_relative "../galician_xiada/lemmatizer"
require_relative "../galician_xiada/pruning_system"
require_relative "../galician_xiada/enclitics_rules"

# galician_xiada_oral profile
require_relative "../galician_xiada_oral/lemmatizer"
require_relative "../galician_xiada_oral/pruning_system"
require_relative "../galician_xiada_oral/enclitics_rules"

# galician_palmed profile
require_relative "../galician_palmed/lemmatizer"
require_relative "../galician_palmed/pruning_system"
require_relative "../galician_palmed/enclitics_rules"

module Config
  class Tagger
    attr_reader :profile, :database, :seseo, :only_lexicon, :force_proper_nouns
    attr_reader :proper_nouns_processor, :dw, :lemmatizer, :pruning_system, :enclitics_rules

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

      proper_nouns_file = "training/lexicons/#{profile}/lexicon_propios.txt"
      @proper_nouns_processor =
        if File.exist?(proper_nouns_file)
          ProperNouns.new(
            ProperNouns.parse_all_lexicon_words("training/lexicons/#{profile}/lexicon_principal.txt"),
            ProperNouns.parse_literals_file(proper_nouns_file),
            CSV.read("training/lexicons/#{profile}/proper_nouns_links.txt", col_sep: "\t").map(&:first),
            CSV.read("training/lexicons/#{profile}/proper_nouns_candidate_tags.txt", col_sep: "\t").map(&:first),
            force_proper_nouns:
          )
        else
          nil
        end

      @dw = DatabaseWrapper.new(self)
      @lemmatizer = "#{profile.camelize}::Lemmatizer".constantize.new(self)
      @pruning_system = "#{profile.camelize}::PruningSystem".constantize.new
      @enclitics_rules = "#{profile.camelize}::EncliticsRules".constantize.new
    end

    def force_proper_nouns = @proper_nouns_processor&.force_proper_nouns
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
end
