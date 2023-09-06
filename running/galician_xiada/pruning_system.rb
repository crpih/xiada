class PruningSystem
def initialize
end
def process(window)
# RULE: no|No,Raa3ms,o,no,x
if (window[0][0] =~ /^(no|No)$/) and (window[0][1] =~ /^(Raa3ms)$/) and (match_some_lemma(window[0][2],"o")) and (window[0][3] =~ /^(no)$/)
return 1
end
# RULE: na|Na,Raa3fs,o,na,x
if (window[0][0] =~ /^(na|Na)$/) and (window[0][1] =~ /^(Raa3fs)$/) and (match_some_lemma(window[0][2],"o")) and (window[0][3] =~ /^(na)$/)
return 1
end
# RULE: nos|Nos,Raa3mp,o,nos,x
if (window[0][0] =~ /^(nos|Nos)$/) and (window[0][1] =~ /^(Raa3mp)$/) and (match_some_lemma(window[0][2],"o")) and (window[0][3] =~ /^(nos)$/)
return 1
end
# RULE: nas|Nas,Raa3fp,o,nas,x
if (window[0][0] =~ /^(nas|Nas)$/) and (window[0][1] =~ /^(Raa3fp)$/) and (match_some_lemma(window[0][2],"o")) and (window[0][3] =~ /^(nas)$/)
return 1
end
# RULE: menos|máis,W.,_,_	con,P,con,_	a,Ddfs,o,_,x
if (window[0][0] =~ /^(menos|máis)$/) and (window[0][1] =~ /^(W.)$/) and (window[1][0] =~ /^(con)$/) and (window[1][1] =~ /^(P)$/) and (match_some_lemma(window[1][2],"con")) and (window[2][0] =~ /^(a)$/) and (window[2][1] =~ /^(Ddfs)$/) and (match_some_lemma(window[2][2],"o"))
return 3
end
# RULE: con,P,con,_	a,Ddfs,o,_,x	_,S.m.|A.m.|V0x*|V0f*,_,_
if (window[0][0] =~ /^(con)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"con")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(Ddfs)$/) and (match_some_lemma(window[1][2],"o")) and (window[2][1] =~ /^(S.m.|A.m.|V0x.*|V0f.*)$/)
return 2
end
# RULE: dona,Scfs,dona|dono,_,x	_,Spf0,_,_
if (window[0][0] =~ /^(dona)$/) and (window[0][1] =~ /^(Scfs)$/) and (match_some_lemma(window[0][2],"dona|dono")) and (window[1][1] =~ /^(Spf0)$/)
return 1
end
# RULE: con,P,con,ca	a,Ddfs,o,_,x	_,D*|E*|M*m.|I.m.|R*|*p,_,_
if (window[0][0] =~ /^(con)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"con")) and (window[0][3] =~ /^(ca)$/) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(Ddfs)$/) and (match_some_lemma(window[1][2],"o")) and (window[2][1] =~ /^(D.*|E.*|M.*m.|I.m.|R.*|.*p)$/)
return 2
end
# RULE: a|as|o|os|a\/o|o\/a|as\/os|os\/as|@|@s,Dd*,_,!á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ó|ao|do|co|no|có|pró|ós|aos|dos|cos|nos|cós|prós,x	_,V.i*|V.s*,_,_
if (window[0][0] =~ /^(a|as|o|os|a\/o|o\/a|as\/os|os\/as|@|@s)$/) and (window[0][1] =~ /^(Dd.*)$/) and (window[0][3] !~ /^(á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ó|ao|do|co|no|có|pró|ós|aos|dos|cos|nos|cós|prós)$/) and (window[1][1] =~ /^(V.i.*|V.s.*)$/)
return 1
end
# RULE: a|as|o|os,Scm.,_,_,x	_,V.i*|V.s*,_,_
if (window[0][0] =~ /^(a|as|o|os)$/) and (window[0][1] =~ /^(Scm.)$/) and (window[1][1] =~ /^(V.i.*|V.s.*)$/)
return 1
end
# RULE: a|as|os,Dd*,_,!á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ós|aos|dos|cos|nos|cós|prós,x	_,V.f*|V0x*,_,_
if (window[0][0] =~ /^(a|as|os)$/) and (window[0][1] =~ /^(Dd.*)$/) and (window[0][3] !~ /^(á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ós|aos|dos|cos|nos|cós|prós)$/) and (window[1][1] =~ /^(V.f.*|V0x.*)$/)
return 1
end
# RULE: a|as|o|os,Dd*,_,!á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ó|ao|do|co|no|có|pró|ós|aos|dos|cos|nos|cós|prós,x	_,V.i*|V.s*,_,_
if (window[0][0] =~ /^(a|as|o|os)$/) and (window[0][1] =~ /^(Dd.*)$/) and (window[0][3] !~ /^(á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ó|ao|do|co|no|có|pró|ós|aos|dos|cos|nos|cós|prós)$/) and (window[1][1] =~ /^(V.i.*|V.s.*)$/)
return 1
end
# RULE: a|as|o|os,Scm.,_,_,x	_,V.i*|V.s*,_,_
if (window[0][0] =~ /^(a|as|o|os)$/) and (window[0][1] =~ /^(Scm.)$/) and (window[1][1] =~ /^(V.i.*|V.s.*)$/)
return 1
end
# RULE: como,_,como,_	_,Raa*,o,_,x	de,P,_,!da|!das|!dese|!deses|!destes_
if (window[0][0] =~ /^(como)$/) and (match_some_lemma(window[0][2],"como")) and (window[1][1] =~ /^(Raa.*)$/) and (match_some_lemma(window[1][2],"o")) and (window[2][0] =~ /^(de)$/) and (window[2][1] =~ /^(P)$/) and (window[2][3] !~ /^(da|!das|!dese|!deses|!destes_)$/)
return 2
end
# RULE: como,_,como,_	_,Raa*,o,_,x	de,P,_,da|das_	a|as,Ddf.,_,_,	_,*f.,_,_
if (window[0][0] =~ /^(como)$/) and (match_some_lemma(window[0][2],"como")) and (window[1][1] =~ /^(Raa.*)$/) and (match_some_lemma(window[1][2],"o")) and (window[2][0] =~ /^(de)$/) and (window[2][1] =~ /^(P)$/) and (window[2][3] =~ /^(da|das_)$/) and (window[3][0] =~ /^(a|as)$/) and (window[3][1] =~ /^(Ddf.)$/) and (window[4][1] =~ /^(.*f.)$/)
return 2
end
# RULE: a,P,_,_,x	_,V.i*|V.s*,_,_
if (window[0][0] =~ /^(a)$/) and (window[0][1] =~ /^(P)$/) and (window[1][1] =~ /^(V.i.*|V.s.*)$/)
return 1
end
# RULE: a,Ddfs,o,!á|!da|!coa|!na|!cá|!prá,x	_,D.ms|E.ms|M*ms|I.ms,_,_
if (window[0][0] =~ /^(a)$/) and (window[0][1] =~ /^(Ddfs)$/) and (match_some_lemma(window[0][2],"o")) and (window[0][3] !~ /^(á|!da|!coa|!na|!cá|!prá)$/) and (window[1][1] =~ /^(D.ms|E.ms|M.*ms|I.ms)$/)
return 1
end
# RULE: _,A*|D.m.|.d*,_,_,x	_,V0f*,impor,_	te,Ra*,te,_
if (window[0][1] =~ /^(A.*|D.m.|.d.*)$/) and (window[1][1] =~ /^(V0f.*)$/) and (match_some_lemma(window[1][2],"impor")) and (window[2][0] =~ /^(te)$/) and (window[2][1] =~ /^(Ra.*)$/) and (match_some_lemma(window[2][2],"te"))
return 1
end
# RULE: _,A*|D.m.|.d*,_,_,x	importe,V*,importar,_
if (window[0][1] =~ /^(A.*|D.m.|.d.*)$/) and (window[1][0] =~ /^(importe)$/) and (window[1][1] =~ /^(V.*)$/) and (match_some_lemma(window[1][2],"importar"))
return 1
end
# RULE: _,V0f*,impor,_	te,Ra*,te,_	_,A*,_,x,_
if (window[0][1] =~ /^(V0f.*)$/) and (match_some_lemma(window[0][2],"impor")) and (window[1][0] =~ /^(te)$/) and (window[1][1] =~ /^(Ra.*)$/) and (match_some_lemma(window[1][2],"te")) and (window[2][1] =~ /^(A.*)$/) and (window[2][3] =~ /^(x)$/)
return 3
end
# RULE: importe,V*,importar,_	_,A*,_,_,x
if (window[0][0] =~ /^(importe)$/) and (window[0][1] =~ /^(V.*)$/) and (match_some_lemma(window[0][2],"importar")) and (window[1][1] =~ /^(A.*)$/)
return 2
end
# RULE: por,P,por,_	importe,V*,importar,_,x	de,P,de,_
if (window[0][0] =~ /^(por)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"por")) and (window[1][0] =~ /^(importe)$/) and (window[1][1] =~ /^(V.*)$/) and (match_some_lemma(window[1][2],"importar")) and (window[2][0] =~ /^(de)$/) and (window[2][1] =~ /^(P)$/) and (match_some_lemma(window[2][2],"de"))
return 2
end
# RULE: cre,Vpi30s,crer,_,x	o,Raa3ms,o,_	que,Cs,que,_
if (window[0][0] =~ /^(cre)$/) and (window[0][1] =~ /^(Vpi30s)$/) and (match_some_lemma(window[0][2],"crer")) and (window[1][0] =~ /^(o)$/) and (window[1][1] =~ /^(Raa3ms)$/) and (match_some_lemma(window[1][2],"o")) and (window[2][0] =~ /^(que)$/) and (window[2][1] =~ /^(Cs)$/) and (match_some_lemma(window[2][2],"que"))
return 1
end
# RULE: en,P,en,_	os,Ddmp,o,_,x	_,V*,_,_
if (window[0][0] =~ /^(en)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"en")) and (window[1][0] =~ /^(os)$/) and (window[1][1] =~ /^(Ddmp)$/) and (match_some_lemma(window[1][2],"o")) and (window[2][1] =~ /^(V.*)$/)
return 2
end
# RULE: de,_,de,_	momento,_,momento,_,x	_,V*,_,_
if (window[0][0] =~ /^(de)$/) and (match_some_lemma(window[0][2],"de")) and (window[1][0] =~ /^(momento)$/) and (match_some_lemma(window[1][2],"momento")) and (window[2][1] =~ /^(V.*)$/)
return 2
end
# RULE: de,P,de,dunha	unha vez,L*,unha vez,_,x
if (window[0][0] =~ /^(de)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"de")) and (window[0][3] =~ /^(dunha)$/) and (window[1][0] =~ /^(unha vez)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2],"unha vez"))
return 2
end
# RULE: con,P,con,cunha	unha vez,L*,unha vez,_,x
if (window[0][0] =~ /^(con)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"con")) and (window[0][3] =~ /^(cunha)$/) and (window[1][0] =~ /^(unha vez)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2],"unha vez"))
return 2
end
# RULE: en,P,en,nunha	unha vez,L*,unha vez,_,x
if (window[0][0] =~ /^(en)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"en")) and (window[0][3] =~ /^(nunha)$/) and (window[1][0] =~ /^(unha vez)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2],"unha vez"))
return 2
end
# RULE: de,P,de,da	a forza de,L*,a forza de,_,x
if (window[0][0] =~ /^(de)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"de")) and (window[0][3] =~ /^(da)$/) and (window[1][0] =~ /^(a forza de)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2],"a forza de"))
return 2
end
# RULE: con,P,con,coa	a forza de,L*,a forza de,_,x
if (window[0][0] =~ /^(con)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"con")) and (window[0][3] =~ /^(coa)$/) and (window[1][0] =~ /^(a forza de)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2],"a forza de"))
return 2
end
# RULE: en,P,en,na	a forza de,L*,a forza de,_,x
if (window[0][0] =~ /^(en)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"en")) and (window[0][3] =~ /^(na)$/) and (window[1][0] =~ /^(a forza de)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2],"a forza de"))
return 2
end
# RULE: se,Rao3aa,se,se,x	non,_,non,_
if (window[0][0] =~ /^(se)$/) and (window[0][1] =~ /^(Rao3aa)$/) and (match_some_lemma(window[0][2],"se")) and (window[0][3] =~ /^(se)$/) and (window[1][0] =~ /^(non)$/) and (match_some_lemma(window[1][2],"non"))
return 1
end
# RULE: se,Rao3aa,_,se,x	se,Rao3aa,_,_	_,V*|Rad*,_,_
if (window[0][0] =~ /^(se)$/) and (window[0][1] =~ /^(Rao3aa)$/) and (window[0][3] =~ /^(se)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(Rao3aa)$/) and (window[2][1] =~ /^(V.*|Rad.*)$/)
return 1
end
# RULE: se,Rao3aa,_,!se	se,Rao3aa,_,se,x
if (window[0][0] =~ /^(se)$/) and (window[0][1] =~ /^(Rao3aa)$/) and (window[0][3] !~ /^(se)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(Rao3aa)$/) and (window[1][3] =~ /^(se)$/)
return 2
end
# RULE: se,Rao3aa,_,se	se,Cs,_,se,x
if (window[0][0] =~ /^(se)$/) and (window[0][1] =~ /^(Rao3aa)$/) and (window[0][3] =~ /^(se)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(Cs)$/) and (window[1][3] =~ /^(se)$/)
return 2
end
# RULE: coma,Cs,_,_	se,Rao3aa,se,se,x	_,Ves*,_,_
if (window[0][0] =~ /^(coma)$/) and (window[0][1] =~ /^(Cs)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(Rao3aa)$/) and (match_some_lemma(window[1][2],"se")) and (window[1][3] =~ /^(se)$/) and (window[2][1] =~ /^(Ves.*)$/)
return 2
end
# RULE: como,Wr,_,_	se,Rao3aa,se,se,x	_,Ves*,_,_
if (window[0][0] =~ /^(como)$/) and (window[0][1] =~ /^(Wr)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(Rao3aa)$/) and (match_some_lemma(window[1][2],"se")) and (window[1][3] =~ /^(se)$/) and (window[2][1] =~ /^(Ves.*)$/)
return 2
end
# RULE: en,_,en,_	canto,_,canto,_,x	_,V.s*,_,_
if (window[0][0] =~ /^(en)$/) and (match_some_lemma(window[0][2],"en")) and (window[1][0] =~ /^(canto)$/) and (match_some_lemma(window[1][2],"canto")) and (window[2][1] =~ /^(V.s.*)$/)
return 2
end
# RULE: en,_,en,_	canto,_,canto,_	a,_,a,_	_,D*,_,ao|aos|á|ás|ó|ós,x
if (window[0][0] =~ /^(en)$/) and (match_some_lemma(window[0][2],"en")) and (window[1][0] =~ /^(canto)$/) and (match_some_lemma(window[1][2],"canto")) and (window[2][0] =~ /^(a)$/) and (match_some_lemma(window[2][2],"a")) and (window[3][1] =~ /^(D.*)$/) and (window[3][3] =~ /^(ao|aos|á|ás|ó|ós)$/)
return 4
end
# RULE: en,_,en,_	canto,_,canto,_	a,_,a,_,x	_,S..p|S.m.,_,_
if (window[0][0] =~ /^(en)$/) and (match_some_lemma(window[0][2],"en")) and (window[1][0] =~ /^(canto)$/) and (match_some_lemma(window[1][2],"canto")) and (window[2][0] =~ /^(a)$/) and (match_some_lemma(window[2][2],"a")) and (window[3][1] =~ /^(S..p|S.m.)$/)
return 3
end
# RULE: compre,Vps30s,comprar,_,x	_,V0f*,_,_
if (window[0][0] =~ /^(compre)$/) and (window[0][1] =~ /^(Vps30s)$/) and (match_some_lemma(window[0][2],"comprar")) and (window[1][1] =~ /^(V0f.*)$/)
return 1
end
# RULE: compre,Vpi30s,cumprir,_,x	_,Sc.p,_,_
if (window[0][0] =~ /^(compre)$/) and (window[0][1] =~ /^(Vpi30s)$/) and (match_some_lemma(window[0][2],"cumprir")) and (window[1][1] =~ /^(Sc.p)$/)
return 1
end
# RULE: _,R*|Tn*,_,_	compre,Vps30s,cumprir,_,x
if (window[0][1] =~ /^(R.*|Tn.*)$/) and (window[1][0] =~ /^(compre)$/) and (window[1][1] =~ /^(Vps30s)$/) and (match_some_lemma(window[1][2],"cumprir"))
return 2
end
# RULE: _,V*,_,_	cara,_,_,_	a,_,_,_	_,_,o,_,x
if (window[0][1] =~ /^(V.*)$/) and (window[1][0] =~ /^(cara)$/) and (window[2][0] =~ /^(a)$/) and (match_some_lemma(window[3][2],"o"))
return 4
end
# RULE: _,V*,_,_	cara,_,_,_	á,_,_,_,x
if (window[0][1] =~ /^(V.*)$/) and (window[1][0] =~ /^(cara)$/) and (window[2][0] =~ /^(á)$/)
return 3
end
# RULE: _,V*,_,_	cara,_,_,_	a,_,_,_,x
if (window[0][1] =~ /^(V.*)$/) and (window[1][0] =~ /^(cara)$/) and (window[2][0] =~ /^(a)$/)
return 3
end
# RULE: cara,_,cara,_	a,Ddfs|P|Raa3fs|Scms,_,_,x	abaixo|adiante|diante|alá|aló|arriba|atrás|dentro|fóra|ningures,_,_,_
if (window[0][0] =~ /^(cara)$/) and (match_some_lemma(window[0][2],"cara")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(Ddfs|P|Raa3fs|Scms)$/) and (window[2][0] =~ /^(abaixo|adiante|diante|alá|aló|arriba|atrás|dentro|fóra|ningures)$/)
return 2
end
# RULE: cara,_,cara,_	a,Ddfs|P|Raa3fs|Scms,_,_,x	_,Wg|Wr,_,_
if (window[0][0] =~ /^(cara)$/) and (match_some_lemma(window[0][2],"cara")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(Ddfs|P|Raa3fs|Scms)$/) and (window[2][1] =~ /^(Wg|Wr)$/)
return 2
end
# RULE: cara,_,cara|caro,_	a,Ddfs|P|Raa3fs|Scms,_,_,x	abaixo|adiante|diante|alá|aló|arriba|atrás|dentro|fóra|ningures,_,_,_
if (window[0][0] =~ /^(cara)$/) and (match_some_lemma(window[0][2],"cara|caro")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(Ddfs|P|Raa3fs|Scms)$/) and (window[2][0] =~ /^(abaixo|adiante|diante|alá|aló|arriba|atrás|dentro|fóra|ningures)$/)
return 2
end
# RULE: cara,P,cara,_	a,P,_,_,x	_,_,_,!ao|á|aos|ás|ó|ós
if (window[0][0] =~ /^(cara)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"cara")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(P)$/) and (window[2][3] !~ /^(ao|á|aos|ás|ó|ós)$/)
return 2
end
# RULE: cara,P,cara,_	a,P,_,_,	_,_,_,ao|á|aos|ás|ó|ós,x
if (window[0][0] =~ /^(cara)$/) and (window[0][1] =~ /^(P)$/) and (match_some_lemma(window[0][2],"cara")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(P)$/) and (window[2][3] =~ /^(ao|á|aos|ás|ó|ós)$/)
return 3
end
# RULE: para,Vpi30s,parar,_,x	_,Ra*,_,_	_,V0f*,_,_	
if (window[0][0] =~ /^(para)$/) and (window[0][1] =~ /^(Vpi30s)$/) and (match_some_lemma(window[0][2],"parar")) and (window[1][1] =~ /^(Ra.*)$/) and (window[2][1] =~ /^(V0f.*)$/)
return 1
end
# RULE: non|aínda|que|se,_,_,_	_,V*,_,*mos	me,Rad1.s,me,_	os,Raa3mp,o,_,x
if (window[0][0] =~ /^(non|aínda|que|se)$/) and (window[1][1] =~ /^(V.*)$/) and (window[1][3] =~ /^(.*mos)$/) and (window[2][0] =~ /^(me)$/) and (window[2][1] =~ /^(Rad1.s)$/) and (match_some_lemma(window[2][2],"me")) and (window[3][0] =~ /^(os)$/) and (window[3][1] =~ /^(Raa3mp)$/) and (match_some_lemma(window[3][2],"o"))
return 4
end
# RULE: nós,Rt*,_,_	_,V*,_,*mos	me,Rad1.s,me,_	os,Raa3mp,o,_,x
if (window[0][0] =~ /^(nós)$/) and (window[0][1] =~ /^(Rt.*)$/) and (window[1][1] =~ /^(V.*)$/) and (window[1][3] =~ /^(.*mos)$/) and (window[2][0] =~ /^(me)$/) and (window[2][1] =~ /^(Rad1.s)$/) and (match_some_lemma(window[2][2],"me")) and (window[3][0] =~ /^(os)$/) and (window[3][1] =~ /^(Raa3mp)$/) and (match_some_lemma(window[3][2],"o"))
return 4
end
# RULE: _,Ra*,_,_	_,V*,_,*mos	me,Rad1.s,me,_	os,Raa3mp,o,_,x
if (window[0][1] =~ /^(Ra.*)$/) and (window[1][1] =~ /^(V.*)$/) and (window[1][3] =~ /^(.*mos)$/) and (window[2][0] =~ /^(me)$/) and (window[2][1] =~ /^(Rad1.s)$/) and (match_some_lemma(window[2][2],"me")) and (window[3][0] =~ /^(os)$/) and (window[3][1] =~ /^(Raa3mp)$/) and (match_some_lemma(window[3][2],"o"))
return 4
end
# RULE: _,V*,_,*mos	me,Rad1.s,me,_	os,Raa3mp,o,_,x	_,A0.p|V0p0.p|Sc*|D*,_,_
if (window[0][1] =~ /^(V.*)$/) and (window[0][3] =~ /^(.*mos)$/) and (window[1][0] =~ /^(me)$/) and (window[1][1] =~ /^(Rad1.s)$/) and (match_some_lemma(window[1][2],"me")) and (window[2][0] =~ /^(os)$/) and (window[2][1] =~ /^(Raa3mp)$/) and (match_some_lemma(window[2][2],"o")) and (window[3][1] =~ /^(A0.p|V0p0.p|Sc.*|D.*)$/)
return 3
end
# RULE: está,_,estar,_	me,Rad1.s,me,_	os,Raa3mp,o,_,x	_,V0x000,_,_	_,Sc*|D*|Ra*A0.p|V0p0.p|,_,_
if (window[0][0] =~ /^(está)$/) and (match_some_lemma(window[0][2],"estar")) and (window[1][0] =~ /^(me)$/) and (window[1][1] =~ /^(Rad1.s)$/) and (match_some_lemma(window[1][2],"me")) and (window[2][0] =~ /^(os)$/) and (window[2][1] =~ /^(Raa3mp)$/) and (match_some_lemma(window[2][2],"o")) and (window[3][1] =~ /^(V0x000)$/) and (window[4][1] =~ /^(Sc.*|D.*|Ra.*A0.p|V0p0.p|)$/)
return 3
end
# RULE: está,_,estar,_	me,Rad1.s,me,_	os,Raa3mp,o,_,x	_,_,en|ante|perante|diante,_
if (window[0][0] =~ /^(está)$/) and (match_some_lemma(window[0][2],"estar")) and (window[1][0] =~ /^(me)$/) and (window[1][1] =~ /^(Rad1.s)$/) and (match_some_lemma(window[1][2],"me")) and (window[2][0] =~ /^(os)$/) and (window[2][1] =~ /^(Raa3mp)$/) and (match_some_lemma(window[2][2],"o")) and (match_some_lemma(window[3][2],"en|ante|perante|diante"))
return 3
end
# RULE: Nós,Sp*,_,_,x	_,V.i10p,_,_
if (window[0][0] =~ /^(Nós)$/) and (window[0][1] =~ /^(Sp.*)$/) and (window[1][1] =~ /^(V.i10p)$/)
return 1
end
# RULE: Nós,Sp*,_,_,x	_,Wn,_,_	_,V.i10p,_,_
if (window[0][0] =~ /^(Nós)$/) and (window[0][1] =~ /^(Sp.*)$/) and (window[1][1] =~ /^(Wn)$/) and (window[2][1] =~ /^(V.i10p)$/)
return 1
end
# RULE: fora,Wn|P,fora,_,x	_,V0p*,_,_
if (window[0][0] =~ /^(fora)$/) and (window[0][1] =~ /^(Wn|P)$/) and (match_some_lemma(window[0][2],"fora")) and (window[1][1] =~ /^(V0p.*)$/)
return 1
end
# RULE: _,D.ms,_,_,	aquel,E.ms,aquel,_,x
if (window[0][1] =~ /^(D.ms)$/) and (window[1][0] =~ /^(aquel)$/) and (window[1][1] =~ /^(E.ms)$/) and (match_some_lemma(window[1][2],"aquel"))
return 2
end
# RULE: _,Ddfs,_,a,x	_,E*,_,_
if (window[0][1] =~ /^(Ddfs)$/) and (window[0][3] =~ /^(a)$/) and (window[1][1] =~ /^(E.*)$/)
return 1
end
# RULE: _,V*,_,_,	_,Ra*,_,se|o|os|a|as|nos,x	_,!V*|!Ra*,_,_
if (window[0][1] =~ /^(V.*)$/) and (window[1][1] =~ /^(Ra.*)$/) and (window[1][3] =~ /^(se|o|os|a|as|nos)$/) and (window[2][1] !~ /^(V.*|!Ra.*)$/)
return 2
end
# RULE: *ei|*ou|*éi|óu,V*,_,_,	o|a|os|as,Raa3*,o,o|a|os|as,x
if (window[0][0] =~ /^(.*ei|.*ou|.*éi|óu)$/) and (window[0][1] =~ /^(V.*)$/) and (window[1][0] =~ /^(o|a|os|as)$/) and (window[1][1] =~ /^(Raa3.*)$/) and (match_some_lemma(window[1][2],"o")) and (window[1][3] =~ /^(o|a|os|as)$/)
return 2
end
# RULE: _,V*,estar|andar|ser|volver|comezar|empezar|chegar|vir|botar|poñer,_,	a,Raa3fs|Ddfs,_,a,x	*ar|*er|*ir*|*or,V0*,_,_
if (window[0][1] =~ /^(V.*)$/) and (match_some_lemma(window[0][2],"estar|andar|ser|volver|comezar|empezar|chegar|vir|botar|poñer")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(Raa3fs|Ddfs)$/) and (window[1][3] =~ /^(a)$/) and (window[2][0] =~ /^(.*ar|.*er|.*ir.*|.*or)$/) and (window[2][1] =~ /^(V0.*)$/)
return 2
end
# RULE: ambos,Inmp,ambos,_,x	os,Ddmp,o,_,	dous,_,_,_
if (window[0][0] =~ /^(ambos)$/) and (window[0][1] =~ /^(Inmp)$/) and (match_some_lemma(window[0][2],"ambos")) and (window[1][0] =~ /^(os)$/) and (window[1][1] =~ /^(Ddmp)$/) and (match_some_lemma(window[1][2],"o")) and (window[2][0] =~ /^(dous)$/)
return 1
end
# RULE: ambas,Infp,ambos,_,x	as,Ddfp,o,_,	dúas,_,_,_
if (window[0][0] =~ /^(ambas)$/) and (window[0][1] =~ /^(Infp)$/) and (match_some_lemma(window[0][2],"ambos")) and (window[1][0] =~ /^(as)$/) and (window[1][1] =~ /^(Ddfp)$/) and (match_some_lemma(window[1][2],"o")) and (window[2][0] =~ /^(dúas)$/)
return 1
end
# RULE: con|de|en|entre|para|sen,P,_,_	_,V.i*|V.s*,_,_,x	me,_,_,_,	_,Raa3*,_,_
if (window[0][0] =~ /^(con|de|en|entre|para|sen)$/) and (window[0][1] =~ /^(P)$/) and (window[1][1] =~ /^(V.i.*|V.s.*)$/) and (window[2][0] =~ /^(me)$/) and (window[3][1] =~ /^(Raa3.*)$/)
return 2
end
# RULE: con|de|en|entre|para|sen,P,_,_	_,V.i*|V.s*,_,_,x	_,Raa3*,_,!o|!a|!os|!as
if (window[0][0] =~ /^(con|de|en|entre|para|sen)$/) and (window[0][1] =~ /^(P)$/) and (window[1][1] =~ /^(V.i.*|V.s.*)$/) and (window[2][1] =~ /^(Raa3.*)$/) and (window[2][3] !~ /^(o|!a|!os|!as)$/)
return 2
end
# RULE: non,_,_,_,	a,P,a,_,x	_,V.i*|V.s*|V0m*,_,_
if (window[0][0] =~ /^(non)$/) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(P)$/) and (match_some_lemma(window[1][2],"a")) and (window[2][1] =~ /^(V.i.*|V.s.*|V0m.*)$/)
return 2
end
# RULE: di,V*,dicir,día,x	a,Raa*,o,_,	tras|a,_,tras|a,tras|a,	día,Scms,día,día,
if (window[0][0] =~ /^(di)$/) and (window[0][1] =~ /^(V.*)$/) and (match_some_lemma(window[0][2],"dicir")) and (window[0][3] =~ /^(día)$/) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(Raa.*)$/) and (match_some_lemma(window[1][2],"o")) and (window[2][0] =~ /^(tras|a)$/) and (match_some_lemma(window[2][2],"tras|a")) and (window[2][3] =~ /^(tras|a)$/) and (window[3][0] =~ /^(día)$/) and (window[3][1] =~ /^(Scms)$/) and (match_some_lemma(window[3][2],"día")) and (window[3][3] =~ /^(día)$/)
return 1
end
# RULE: noite,Scf,noite,noite,	e,Cc,e,e,	di,V*,dicir,día,x
if (window[0][0] =~ /^(noite)$/) and (window[0][1] =~ /^(Scf)$/) and (match_some_lemma(window[0][2],"noite")) and (window[0][3] =~ /^(noite)$/) and (window[1][0] =~ /^(e)$/) and (window[1][1] =~ /^(Cc)$/) and (match_some_lemma(window[1][2],"e")) and (window[1][3] =~ /^(e)$/) and (window[2][0] =~ /^(di)$/) and (window[2][1] =~ /^(V.*)$/) and (match_some_lemma(window[2][2],"dicir")) and (window[2][3] =~ /^(día)$/)
return 3
end
# RULE: di,V*,dicir,día,x	e,Cc,e,e,	noite,Scf,noite,noite
if (window[0][0] =~ /^(di)$/) and (window[0][1] =~ /^(V.*)$/) and (match_some_lemma(window[0][2],"dicir")) and (window[0][3] =~ /^(día)$/) and (window[1][0] =~ /^(e)$/) and (window[1][1] =~ /^(Cc)$/) and (match_some_lemma(window[1][2],"e")) and (window[1][3] =~ /^(e)$/) and (window[2][0] =~ /^(noite)$/) and (window[2][1] =~ /^(Scf)$/) and (match_some_lemma(window[2][2],"noite")) and (window[2][3] =~ /^(noite)$/)
return 1
end
# RULE: gustan|gusten|gustaban|gustarían,_,_,_	os,Raa3mp,o,_,x
if (window[0][0] =~ /^(gustan|gusten|gustaban|gustarían)$/) and (window[1][0] =~ /^(os)$/) and (window[1][1] =~ /^(Raa3mp)$/) and (match_some_lemma(window[1][2],"o"))
return 2
end
# RULE: vir,_,_,vila|vilas,x	_,Raa3f.,_,_,	_,!V0f*,_,_
if (window[0][0] =~ /^(vir)$/) and (window[0][3] =~ /^(vila|vilas)$/) and (window[1][1] =~ /^(Raa3f.)$/) and (window[2][1] !~ /^(V0f.*)$/)
return 1
end
# RULE: cre,_,_,cremos,x	me,_,_,_,	_,Raa3*,_,_,	que|en,_,_,_
if (window[0][0] =~ /^(cre)$/) and (window[0][3] =~ /^(cremos)$/) and (window[1][0] =~ /^(me)$/) and (window[2][1] =~ /^(Raa3.*)$/) and (window[3][0] =~ /^(que|en)$/)
return 1
end
# RULE: cre,_,_,cremos,x	me,_,_,_,	_,Raa3*,_,_,	_,V0f*,_,_
if (window[0][0] =~ /^(cre)$/) and (window[0][3] =~ /^(cremos)$/) and (window[1][0] =~ /^(me)$/) and (window[2][1] =~ /^(Raa3.*)$/) and (window[3][1] =~ /^(V0f.*)$/)
return 1
end
# RULE: como,_,_,_,	_,_,_,*mos,	me,_,_,_	_,Raa3*,_,_,x
if (window[0][0] =~ /^(como)$/) and (window[1][3] =~ /^(.*mos)$/) and (window[2][0] =~ /^(me)$/) and (window[3][1] =~ /^(Raa3.*)$/)
return 4
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
