module LemmatizerGalicianXiadaRefactor
  include LemmatizerGalicianXiada

  # Alias included method to be able to call it after overwriting it
  alias_method :fallback_lemmatize, :lemmatize

  Result = Struct.new(:tag, :lemma, :hyperlemma, :log_prob)

  VOWELS = { 'a' => 'á', 'e' => 'é', 'i' => 'í', 'o' => 'ó', 'u' => 'ú' }.freeze
  GHEADA_REPLACEMENTS = { 'gha' => 'ga', 'ghe' => 'gue', 'ghi' => 'gui', 'gho' => 'go', 'ghu' => 'gu' }.freeze

  VALID_TISIMO = %w[abert absolt acolleit avolt colleit comest cubert descrit descubert desenvolt devolt disolt encolleit encubert entreabert envolt enxoit ergueit escolleit escrit frit mort prescrit proscrit provist recolleit recubert resolt revolt].freeze
  VALID_SISIMO = %w[aces apres impres pres].freeze

  def lemmatize(word, _tags)
    result = handle_isimo([Result.new(nil, word, nil, nil)])
    return result.map { |r| [r.tag, r.lemma, r.hyperlemma, r.log_prob] } unless result.nil?

    fallback_lemmatize(word, nil)
  end

  def handle_isimo(results)
    results.flat_map do |result|
      if result.lemma.match(/ísim[oa]s?\z/)
        find_isimo_lemmas(result).map(&method(:superlative))
      else
        result
      end
    end
  end

  def find_isimo_lemmas(result)
    return unless result.lemma.match(/(.+)ísim([oa])(s?)\z/)

    base, g, n = Regexp.last_match.captures

    if base.end_with?('bil')
      # amabilísimo => amable
      search_tags = ["A*#{gn_tag(g, n)}"]
      find_word("#{base.delete_suffix('il')}le#{n}", search_tags)
    elsif base.end_with?('qu')
      # riquísimo => rico
      find_word("#{base.delete_suffix('qu')}c#{g}#{n}", ['A*'])
    elsif base.end_with?('gu')
      # vaguísimo => vago
      find_word("#{base.delete_suffix('u')}#{g}#{n}", ['A*'])
    elsif base.end_with?('gü')
      # ambigüísimo => ambiguo / pingüísimo => pingüe
      search_base = base.delete_suffix('ü')
      [*find_word("#{search_base}u#{g}#{n}", ['A*']),
       *find_word("#{search_base}üe#{n}", ["A*#{gn_tag(g, n)}"])]
    elsif base.end_with?('i')
      # friísimo => frío
      find_word("#{base.delete_suffix('i')}í#{g}#{n}", ['A*'])
    elsif base == 'cool'
      # Plural exception: cool
      find_word(base, ["A_#{gn_tag(g, n)}"])
    elsif base.end_with?('l')
      # virtualísimo => virtual
      # facilísimo => fácil
      tilde_combinations(base).flat_map { |c| find_word(c, ["A_#{gn_tag(g, n)}"]) }
    elsif base.end_with?('c')
      # ferocísimo => feroz
      # docísimo => doce
      search_base = base.delete_suffix('c')
      [*find_word("#{search_base}z", ["A_#{gn_tag(g, n)}"]),
       *find_word("#{search_base}ces", ["A_#{gn_tag(g, n)}"])]
    elsif base.end_with?('ad')
      # preparadísimo => preparado
      find_word("#{base}#{g}#{n}", %w[V0p* A*])
    elsif base.end_with?('id')
      # convencidísimos => convencidos
      # extendidísima => extendida
      find_word("#{base}#{g}#{n}", %w[V0p* A*])
    elsif base.end_with?('t') && VALID_TISIMO.include?(base)
      find_word("#{base}#{g}#{n}", %w[V0p* A*])
    elsif base.end_with?('s') && VALID_SISIMO.include?(base)
      find_word("#{base}#{g}#{n}", %w[V0p* A*])
    else
      # ísimo (default rule)
      # listísimo => listo
      # gravísimo => grave
      [*find_word(base, ["A_#{gn_tag(g, n)}"]),
       *find_word(normalize_gheada(base), ["A_#{gn_tag(g, n)}"])]
    end
  end

  def superlative(result)
    result.tap { |r| r.tag = r.tag.sub(/\AA0/, 'As') }
  end

  def normalize_gheada(word)
    word.gsub(/gh[aeiou]/, GHEADA_REPLACEMENTS)
  end

  def gn_tag(gender_suffix, number_suffix)
    number_tag = number_suffix.nil? ? 's' : 'p'
    gender_suffix == 'o' ? "m#{number_tag}" : "f#{number_tag}"
  end

  def find_word(word, search_tags)
    @dw.get_emissions_info(word, search_tags)
       .map { |tag, lemma, hyperlemma, lob_prob| Result.new(tag, lemma, hyperlemma, lob_prob) }
  end

  def tilde_combinations(word)
    tildes = word.each_char.with_index.filter_map do |char, i|
      next unless VOWELS.keys.include?(char)

      word.dup.tap { |w| w[i] = VOWELS[w[i]] }
    end
    [word, *tildes]
  end
end
