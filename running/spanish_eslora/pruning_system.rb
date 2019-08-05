class PruningSystem
def initialize
end
def process(window)
return 0
end
private
def match_some_lemma (lemmas, string)
  lemmas.each do |lemma|
    if lemma =~ /^(#{string})$/
      return true
    end
  end
  return false
end
end
def print_window(window)
  window.each do |element|
    if element != nil
      STDERR.print "(#{element[0]}/#{element[1]}/#{element[2]}/#{element[3]})"
    else
      STDERR.print "(empty/empty/empty/empty)"
    end
  end
  STDERR.puts ""
end
