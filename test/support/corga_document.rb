require 'bundler/setup'
require 'csv'
require 'json'
require 'yaml'
require_relative '../../running/bin/config'
require_relative '../../running/bin/xiada_tagger'

# Recorded output is a baseline of current behavior, not a linguistic gold standard.
module CorgaDocument
  DIRECTORY = File.expand_path('../fixtures/corga_document_20261007', __dir__)
  HISTORICAL_BASELINE = File.join(DIRECTORY, 'baseline.json')
  BASELINE = File.join(DIRECTORY, 'reviewed_baseline.json')
  FIELDS = %i[token tag lemma hiperlemma start finish].freeze

  def self.cases
    @cases ||= JSON.parse(File.read(File.join(DIRECTORY, 'cases.json')))
  end

  def self.active_cases
    cases.reject { |example| example.dig('acceptance', 'status') == 'deferred' }
  end

  def self.baseline
    @baseline ||= JSON.parse(File.read(BASELINE))
  end

  def self.profile_settings(profile)
    profiles = YAML.load_file(File.expand_path('../../profiles.example.yml', __dir__), symbolize_names: true)
    settings = profiles.find { |entry| entry.fetch(:profile) == profile }
    raise "Missing profile: #{profile}" unless settings

    JSON.parse(JSON.generate(settings))
  end

  def self.output(example)
    @taggers ||= {}
    @configs ||= {}
    profile = example.fetch('profile')
    @configs[profile] ||= Config::Tagger.new(**profile_settings(profile).transform_keys(&:to_sym))
    @taggers[profile] ||= XiadaTagger.new(@configs.fetch(profile))
    document = Config::Document.new(seseo: true, gheada: true)
    @taggers.fetch(profile).tag_texts(document, [example.fetch('input')]).first.map do |token|
      # Keep every field exposed by best_way, including source positions.
      token.transform_keys(&:to_s)
    end
  end

  def self.close
    @configs&.each_value { |config| config.dw.close_database }
    @configs = {}
    @taggers = {}
  end

  # Explicit one-time capture; normal tests never create or overwrite snapshots.
  def self.capture
    raise "Baseline already exists; refusing to overwrite #{BASELINE}" if File.exist?(BASELINE)

    profiles = cases.filter_map { |example| example['profile'] }.uniq
    results = {}
    failures = 0
    cases.each do |example|
      id = example.fetch('id')
      if example.fetch('kind') == 'manual'
        results[id] = { 'status' => 'manual', 'reason' => example.fetch('reason') }
        next
      end

      begin
        results[id] = { 'status' => 'tagged', 'input' => example.fetch('input'), 'tokens' => output(example) }
      rescue XiadaTagger::Exception => error
        failures += 1
        results[id] = { 'status' => 'error', 'input' => example.fetch('input'),
                        'error' => { 'class' => error.class.name, 'message' => error.message } }
      end
    end
    captured = { 'profiles' => profiles.to_h { |profile| [profile, profile_settings(profile)] },
                 'document' => { 'seseo' => true, 'gheada' => true }, 'cases' => results }
    File.write(BASELINE, JSON.pretty_generate(captured) + "\n")
    puts "Captured #{results.count { |_, result| result['status'] == 'tagged' }} cases; " \
         "#{results.count { |_, result| result['status'] == 'manual' }} manual checks; #{failures} errors."
    failures.zero? ? 0 : 1
  ensure
    close
  end
end
