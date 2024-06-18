class PruningSystem
def initialize
end
def process(window)
# RULE: el|un,D.FS,_,_,x	a*|á*|ha*,!NCFS,_,_
if (window[0][0] =~ /^(el|un)$/) and (window[0][1] =~ /^(D.FS)$/) and (window[1][0] =~ /^(a.*|á.*|ha.*)$/) and (window[1][1] !~ /^(NCFS)$/)
return 1
end
# RULE: !hay,_,haber,_,	*ado|*ido,!VPMS,_,_,x
if (window[0][0] !~ /^(hay)$/) and (match_some_lemma(window[0][2],"haber")) and (window[1][0] =~ /^(.*ado|.*ido)$/) and (window[1][1] !~ /^(VPMS)$/)
return 2
end
# RULE: vamos,I,_,_,x	a,X,_,_	_,VNP,_,_
if (window[0][0] =~ /^(vamos)$/) and (window[0][1] =~ /^(I)$/) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(X)$/) and (window[2][1] =~ /^(VNP)$/)
return 1
end
# RULE: vamos,I,_,_,x	_,VNP,_,_
if (window[0][0] =~ /^(vamos)$/) and (window[0][1] =~ /^(I)$/) and (window[1][1] =~ /^(VNP)$/)
return 1
end
# RULE: vamos,I,_,_,x	a,X,_,_	_,NPEL,_,_
if (window[0][0] =~ /^(vamos)$/) and (window[0][1] =~ /^(I)$/) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(X)$/) and (window[2][1] =~ /^(NPEL)$/)
return 1
end
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
