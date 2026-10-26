module AbbreviationVariants
  # Spaces are optional only at existing component boundaries or between
  # dot-separated components. Ordinal suffixes remain a single component.
  def self.each(form)
    return enum_for(__method__, form) unless block_given?

    components = form.split(/ +|(?<=\.)(?=[\p{L}&&[^ºª]])/)
    boundaries = components.length - 1
    (0...(1 << boundaries)).each do |mask|
      variant = components.first.dup
      components.drop(1).each_with_index do |component, index|
        variant << ' ' if mask[index] == 1
        variant << component
      end
      yield variant
    end
  end
end
