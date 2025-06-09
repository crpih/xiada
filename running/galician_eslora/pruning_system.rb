module GalicianEslora
  class PruningSystem
    def initialize; end

    def process(window)
      # RULE: el|un,D.FS,_,_,x	a*|á*|ha*,!NCFS,_,_
      if (window[0][0] =~ /^(el|un)$/) and (window[0][1] =~ /^(D.FS)$/) and (window[1][0] =~ /^(a.*|á.*|ha.*)$/) and (window[1][1] !~ /^(NCFS)$/)
        return 1
      end
      # RULE: !hay,_,haber,_,	*ado|*ido,!VPMS,_,_,x
      if (window[0][0] !~ /^(hay)$/) and (match_some_lemma(window[0][2], "haber")) and (window[1][0] =~ /^(.*ado|.*ido)$/) and (window[1][1] !~ /^(VPMS)$/)
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
      # RULE: no|No,PY3MSA,o,no,x
      if (window[0][0] =~ /^(no|No)$/) and (window[0][1] =~ /^(PY3MSA)$/) and (match_some_lemma(window[0][2], "o")) and (window[0][3] =~ /^(no)$/)
        return 1
      end
      # RULE: na|Na,PY3FSA,o,na,x
      if (window[0][0] =~ /^(na|Na)$/) and (window[0][1] =~ /^(PY3FSA)$/) and (match_some_lemma(window[0][2], "o")) and (window[0][3] =~ /^(na)$/)
        return 1
      end
      # RULE: nos|Nos,PY3MPW,o,nos,x
      if (window[0][0] =~ /^(nos|Nos)$/) and (window[0][1] =~ /^(PY3MPW)$/) and (match_some_lemma(window[0][2], "o")) and (window[0][3] =~ /^(nos)$/)
        return 1
      end
      # RULE: nas|Nas,PY3FPA,o,nas,x
      if (window[0][0] =~ /^(nas|Nas)$/) and (window[0][1] =~ /^(PY3FPA)$/) and (match_some_lemma(window[0][2], "o")) and (window[0][3] =~ /^(nas)$/)
        return 1
      end
      # RULE: menos|máis|,W.,_,_	con,X,con,_	a,DAFS,o,_,x
      if (window[0][0] =~ /^(menos|máis|)$/) and (window[0][1] =~ /^(W.)$/) and (window[1][0] =~ /^(con)$/) and (window[1][1] =~ /^(X)$/) and (match_some_lemma(window[1][2], "con")) and (window[2][0] =~ /^(a)$/) and (window[2][1] =~ /^(DAFS)$/) and (match_some_lemma(window[2][2], "o"))
        return 3
      end
      # RULE: con,X,con,_	a,DAFS,o,_,x	_,N.M.|A.M.|VGP|VNP,_,_
      if (window[0][0] =~ /^(con)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "con")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(DAFS)$/) and (match_some_lemma(window[1][2], "o")) and (window[2][1] =~ /^(N.M.|A.M.|VGP|VNP)$/)
        return 2
      end
      # RULE: dona,NCFS,dona|dono,_,x	_,NPFL,_,_
      if (window[0][0] =~ /^(dona)$/) and (window[0][1] =~ /^(NCFS)$/) and (match_some_lemma(window[0][2], "dona|dono")) and (window[1][1] =~ /^(NPFL)$/)
        return 1
      end
      # RULE: con,X,con,ca	a,DAFS,o,_,x	_,D*|D*M.|I.M.|P*|*P,_,_
      if (window[0][0] =~ /^(con)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "con")) and (window[0][3] =~ /^(ca)$/) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(DAFS)$/) and (match_some_lemma(window[1][2], "o")) and (window[2][1] =~ /^(D.*|D.*M.|I.M.|P.*|.*P)$/)
        return 2
      end
      # RULE: a|as|o|os|a\/o|o\/a|as\/os|os\/as|@|@s,DA*,_,!á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ó|ao|do|co|no|có|pró|ós|aos|dos|cos|nos|cós|prós,x	_,VI*|VS*,_,_
      if (window[0][0] =~ /^(a|as|o|os|a\/o|o\/a|as\/os|os\/as|@|@s)$/) and (window[0][1] =~ /^(DA.*)$/) and (window[0][3] !~ /^(á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ó|ao|do|co|no|có|pró|ós|aos|dos|cos|nos|cós|prós)$/) and (window[1][1] =~ /^(VI.*|VS.*)$/)
        return 1
      end
      # RULE: a|as|o|os,NCM.,_,_,x	_,VI*|VS*,_,_
      if (window[0][0] =~ /^(a|as|o|os)$/) and (window[0][1] =~ /^(NCM.)$/) and (window[1][1] =~ /^(VI.*|VS.*)$/)
        return 1
      end
      # RULE: a|as|os|o\/a|a\/o|as\/os|os\/as|@|@s,DA*,_,!á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ós|aos|dos|cos|nos|cós|prós,x	_,VNP|VGP,_,_
      if (window[0][0] =~ /^(a|as|os|o\/a|a\/o|as\/os|os\/as|@|@s)$/) and (window[0][1] =~ /^(DA.*)$/) and (window[0][3] !~ /^(á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ós|aos|dos|cos|nos|cós|prós)$/) and (window[1][1] =~ /^(VNP|VGP)$/)
        return 1
      end
      # RULE: a|as|o|os,DA*,_,!á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ó|ao|do|co|no|có|pró|ós|aos|dos|cos|nos|cós|prós,x	_,VI*|VS*,_,_
      if (window[0][0] =~ /^(a|as|o|os)$/) and (window[0][1] =~ /^(DA.*)$/) and (window[0][3] !~ /^(á|da|coa|na|cá|prá|ás|das|coas|nas|cás|prás|ó|ao|do|co|no|có|pró|ós|aos|dos|cos|nos|cós|prós)$/) and (window[1][1] =~ /^(VI.*|VS.*)$/)
        return 1
      end
      # RULE: a|as|o|os,NCM.,_,_,x	_,VI*|VS*,_,_
      if (window[0][0] =~ /^(a|as|o|os)$/) and (window[0][1] =~ /^(NCM.)$/) and (window[1][1] =~ /^(VI.*|VS.*)$/)
        return 1
      end
      # RULE: como,_,como,_	_,PY3*,o,_,x	de,X,_,!da|!das|!dese|!deses|!destes_
      if (window[0][0] =~ /^(como)$/) and (match_some_lemma(window[0][2], "como")) and (window[1][1] =~ /^(PY3.*)$/) and (match_some_lemma(window[1][2], "o")) and (window[2][0] =~ /^(de)$/) and (window[2][1] =~ /^(X)$/) and (window[2][3] !~ /^(da|!das|!dese|!deses|!destes_)$/)
        return 2
      end
      # RULE: como,_,como,_	_,PY3*,o,_,x	de,X,_,da|das_	a|as,DAF.,_,_,	_,*F.,_,_
      if (window[0][0] =~ /^(como)$/) and (match_some_lemma(window[0][2], "como")) and (window[1][1] =~ /^(PY3.*)$/) and (match_some_lemma(window[1][2], "o")) and (window[2][0] =~ /^(de)$/) and (window[2][1] =~ /^(X)$/) and (window[2][3] =~ /^(da|das_)$/) and (window[3][0] =~ /^(a|as)$/) and (window[3][1] =~ /^(DAF.)$/) and (window[4][1] =~ /^(.*F.)$/)
        return 2
      end
      # RULE: a,X,_,_,x	_,VI*|VS*,_,_
      if (window[0][0] =~ /^(a)$/) and (window[0][1] =~ /^(X)$/) and (window[1][1] =~ /^(VI.*|VS.*)$/)
        return 1
      end
      # RULE: a,DAFS,o,!á|!da|!coa|!na|!cá|!prá,x	_,D.MS|D.MS|S*MS|D.MS|P.MS,_,_
      if (window[0][0] =~ /^(a)$/) and (window[0][1] =~ /^(DAFS)$/) and (match_some_lemma(window[0][2], "o")) and (window[0][3] !~ /^(á|!da|!coa|!na|!cá|!prá)$/) and (window[1][1] =~ /^(D.MS|D.MS|S.*MS|D.MS|P.MS)$/)
        return 1
      end
      # RULE: _,A*|D.M.|.d*,_,_,x	_,VNP,impor,_	te,PY*,te,_
      if (window[0][1] =~ /^(A.*|D.M.|.d.*)$/) and (window[1][1] =~ /^(VNP)$/) and (match_some_lemma(window[1][2], "impor")) and (window[2][0] =~ /^(te)$/) and (window[2][1] =~ /^(PY.*)$/) and (match_some_lemma(window[2][2], "te"))
        return 1
      end
      # RULE: _,A*|D.M.|.d*,_,_,x	importe,V*,importar,_
      if (window[0][1] =~ /^(A.*|D.M.|.d.*)$/) and (window[1][0] =~ /^(importe)$/) and (window[1][1] =~ /^(V.*)$/) and (match_some_lemma(window[1][2], "importar"))
        return 1
      end
      # RULE: _,VNP,impor,_	te,PY*,te,_	_,A*,_,x,_
      if (window[0][1] =~ /^(VNP)$/) and (match_some_lemma(window[0][2], "impor")) and (window[1][0] =~ /^(te)$/) and (window[1][1] =~ /^(PY.*)$/) and (match_some_lemma(window[1][2], "te")) and (window[2][1] =~ /^(A.*)$/) and (window[2][3] =~ /^(x)$/)
        return 3
      end
      # RULE: importe,V*,importar,_	_,A*,_,_,x
      if (window[0][0] =~ /^(importe)$/) and (window[0][1] =~ /^(V.*)$/) and (match_some_lemma(window[0][2], "importar")) and (window[1][1] =~ /^(A.*)$/)
        return 2
      end
      # RULE: por,X,por,_	importe,V*,importar,_,x	de,X,de,_
      if (window[0][0] =~ /^(por)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "por")) and (window[1][0] =~ /^(importe)$/) and (window[1][1] =~ /^(V.*)$/) and (match_some_lemma(window[1][2], "importar")) and (window[2][0] =~ /^(de)$/) and (window[2][1] =~ /^(X)$/) and (match_some_lemma(window[2][2], "de"))
        return 2
      end
      # RULE: cre,VIP3S,crer,_,x	o,PY3MSA,o,_	que,C,que,_
      if (window[0][0] =~ /^(cre)$/) and (window[0][1] =~ /^(VIP3S)$/) and (match_some_lemma(window[0][2], "crer")) and (window[1][0] =~ /^(o)$/) and (window[1][1] =~ /^(PY3MSA)$/) and (match_some_lemma(window[1][2], "o")) and (window[2][0] =~ /^(que)$/) and (window[2][1] =~ /^(C)$/) and (match_some_lemma(window[2][2], "que"))
        return 1
      end
      # RULE: en,X,en,_	os,DAMP,o,_,x	_,V*,_,_
      if (window[0][0] =~ /^(en)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "en")) and (window[1][0] =~ /^(os)$/) and (window[1][1] =~ /^(DAMP)$/) and (match_some_lemma(window[1][2], "o")) and (window[2][1] =~ /^(V.*)$/)
        return 2
      end
      # RULE: de,_,de,_	momento,_,momento,_,x	_,V*,_,_
      if (window[0][0] =~ /^(de)$/) and (match_some_lemma(window[0][2], "de")) and (window[1][0] =~ /^(momento)$/) and (match_some_lemma(window[1][2], "momento")) and (window[2][1] =~ /^(V.*)$/)
        return 2
      end
      # RULE: de,X,de,dunha	unha vez,L*,unha vez,_,x
      if (window[0][0] =~ /^(de)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "de")) and (window[0][3] =~ /^(dunha)$/) and (window[1][0] =~ /^(unha vez)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2], "unha vez"))
        return 2
      end
      # RULE: con,X,con,cunha	unha vez,L*,unha vez,_,x
      if (window[0][0] =~ /^(con)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "con")) and (window[0][3] =~ /^(cunha)$/) and (window[1][0] =~ /^(unha vez)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2], "unha vez"))
        return 2
      end
      # RULE: en,X,en,nunha	unha vez,L*,unha vez,_,x
      if (window[0][0] =~ /^(en)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "en")) and (window[0][3] =~ /^(nunha)$/) and (window[1][0] =~ /^(unha vez)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2], "unha vez"))
        return 2
      end
      # RULE: de,X,de,da	a forza de,L*,a forza de,_,x
      if (window[0][0] =~ /^(de)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "de")) and (window[0][3] =~ /^(da)$/) and (window[1][0] =~ /^(a forza de)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2], "a forza de"))
        return 2
      end
      # RULE: con,X,con,coa	a forza de,L*,a forza de,_,x
      if (window[0][0] =~ /^(con)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "con")) and (window[0][3] =~ /^(coa)$/) and (window[1][0] =~ /^(a forza de)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2], "a forza de"))
        return 2
      end
      # RULE: en,X,en,na	a forza de,L*,a forza de,_,x
      if (window[0][0] =~ /^(en)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "en")) and (window[0][3] =~ /^(na)$/) and (window[1][0] =~ /^(a forza de)$/) and (window[1][1] =~ /^(L.*)$/) and (match_some_lemma(window[1][2], "a forza de"))
        return 2
      end
      # RULE: se,PY3ELO|PY3EPO|PY3ESO,se,se,x	non,_,non,_
      if (window[0][0] =~ /^(se)$/) and (window[0][1] =~ /^(PY3ELO|PY3EPO|PY3ESO)$/) and (match_some_lemma(window[0][2], "se")) and (window[0][3] =~ /^(se)$/) and (window[1][0] =~ /^(non)$/) and (match_some_lemma(window[1][2], "non"))
        return 1
      end
      # RULE: se,PY3ELO|PY3EPO|PY3ESO,_,se,x	se,PY3ELO|PY3EPO|PY3ESO,_,_	_,V*|PY.E*,_,_
      if (window[0][0] =~ /^(se)$/) and (window[0][1] =~ /^(PY3ELO|PY3EPO|PY3ESO)$/) and (window[0][3] =~ /^(se)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(PY3ELO|PY3EPO|PY3ESO)$/) and (window[2][1] =~ /^(V.*|PY.E.*)$/)
        return 1
      end
      # RULE: se,PY3ELO|PY3EPO|PY3ESO,_,!se	se,PY3ELO|PY3EPO|PY3ESO,_,se,x
      if (window[0][0] =~ /^(se)$/) and (window[0][1] =~ /^(PY3ELO|PY3EPO|PY3ESO)$/) and (window[0][3] !~ /^(se)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(PY3ELO|PY3EPO|PY3ESO)$/) and (window[1][3] =~ /^(se)$/)
        return 2
      end
      # RULE: se,PY3ELO|PY3EPO|PY3ESO,_,se	se,C,_,se,x
      if (window[0][0] =~ /^(se)$/) and (window[0][1] =~ /^(PY3ELO|PY3EPO|PY3ESO)$/) and (window[0][3] =~ /^(se)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(C)$/) and (window[1][3] =~ /^(se)$/)
        return 2
      end
      # RULE: coma,C,_,_	se,PY3ELO|PY3EPO|PY3ESO,se,se,x	_,VSI*|VSY*,_,_
      if (window[0][0] =~ /^(coma)$/) and (window[0][1] =~ /^(C)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(PY3ELO|PY3EPO|PY3ESO)$/) and (match_some_lemma(window[1][2], "se")) and (window[1][3] =~ /^(se)$/) and (window[2][1] =~ /^(VSI.*|VSY.*)$/)
        return 2
      end
      # RULE: como,W,_,_	se,PY3ELO|PY3EPO|PY3ESO,se,se,x	_,VSI*|VSY*,_,_
      if (window[0][0] =~ /^(como)$/) and (window[0][1] =~ /^(W)$/) and (window[1][0] =~ /^(se)$/) and (window[1][1] =~ /^(PY3ELO|PY3EPO|PY3ESO)$/) and (match_some_lemma(window[1][2], "se")) and (window[1][3] =~ /^(se)$/) and (window[2][1] =~ /^(VSI.*|VSY.*)$/)
        return 2
      end
      # RULE: en,_,en,_	canto,_,canto,_,x	_,VS*,_,_
      if (window[0][0] =~ /^(en)$/) and (match_some_lemma(window[0][2], "en")) and (window[1][0] =~ /^(canto)$/) and (match_some_lemma(window[1][2], "canto")) and (window[2][1] =~ /^(VS.*)$/)
        return 2
      end
      # RULE: en,_,en,_	canto,_,canto,_	a,_,a,_	_,D*,_,ao|aos|á|ás|ó|ós,x
      if (window[0][0] =~ /^(en)$/) and (match_some_lemma(window[0][2], "en")) and (window[1][0] =~ /^(canto)$/) and (match_some_lemma(window[1][2], "canto")) and (window[2][0] =~ /^(a)$/) and (match_some_lemma(window[2][2], "a")) and (window[3][1] =~ /^(D.*)$/) and (window[3][3] =~ /^(ao|aos|á|ás|ó|ós)$/)
        return 4
      end
      # RULE: en,_,en,_	canto,_,canto,_	a,_,a,_,x	_,N..P|N.M.,_,_
      if (window[0][0] =~ /^(en)$/) and (match_some_lemma(window[0][2], "en")) and (window[1][0] =~ /^(canto)$/) and (match_some_lemma(window[1][2], "canto")) and (window[2][0] =~ /^(a)$/) and (match_some_lemma(window[2][2], "a")) and (window[3][1] =~ /^(N..P|N.M.)$/)
        return 3
      end
      # RULE: compre,VSP3S,comprar,_,x	_,VNP,_,_
      if (window[0][0] =~ /^(compre)$/) and (window[0][1] =~ /^(VSP3S)$/) and (match_some_lemma(window[0][2], "comprar")) and (window[1][1] =~ /^(VNP)$/)
        return 1
      end
      # RULE: compre,VIP3S,cumprir,_,x	_,NC.P,_,_
      if (window[0][0] =~ /^(compre)$/) and (window[0][1] =~ /^(VIP3S)$/) and (match_some_lemma(window[0][2], "cumprir")) and (window[1][1] =~ /^(NC.P)$/)
        return 1
      end
      # RULE: _,P*|PL*,_,_	compre,VSP3S,cumprir,_,x
      if (window[0][1] =~ /^(P.*|PL.*)$/) and (window[1][0] =~ /^(compre)$/) and (window[1][1] =~ /^(VSP3S)$/) and (match_some_lemma(window[1][2], "cumprir"))
        return 2
      end
      # RULE: _,V*,_,_	cara,_,_,_	a,_,_,_	_,_,o,_,x
      if (window[0][1] =~ /^(V.*)$/) and (window[1][0] =~ /^(cara)$/) and (window[2][0] =~ /^(a)$/) and (match_some_lemma(window[3][2], "o"))
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
      # RULE: cara,_,cara,_	a,DAFS|P|PY3FSA|NCMS,_,_,x	abaixo|adiante|diante|alá|aló|arriba|atrás|dentro|fóra|ningures,_,_,_
      if (window[0][0] =~ /^(cara)$/) and (match_some_lemma(window[0][2], "cara")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(DAFS|P|PY3FSA|NCMS)$/) and (window[2][0] =~ /^(abaixo|adiante|diante|alá|aló|arriba|atrás|dentro|fóra|ningures)$/)
        return 2
      end
      # RULE: cara,_,cara,_	a,DAFS|P|PY3FSA|NCMS,_,_,x	_,W,_,_
      if (window[0][0] =~ /^(cara)$/) and (match_some_lemma(window[0][2], "cara")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(DAFS|P|PY3FSA|NCMS)$/) and (window[2][1] =~ /^(W)$/)
        return 2
      end
      # RULE: cara,_,cara|caro,_	a,DAFS|P|PY3FSA|NCMS,_,_,x	abaixo|adiante|diante|alá|aló|arriba|atrás|dentro|fóra|ningures,_,_,_
      if (window[0][0] =~ /^(cara)$/) and (match_some_lemma(window[0][2], "cara|caro")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(DAFS|P|PY3FSA|NCMS)$/) and (window[2][0] =~ /^(abaixo|adiante|diante|alá|aló|arriba|atrás|dentro|fóra|ningures)$/)
        return 2
      end
      # RULE: cara,X,cara,_	a,X,_,_,x	_,_,_,!ao|á|aos|ás|ó|ós
      if (window[0][0] =~ /^(cara)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "cara")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(X)$/) and (window[2][3] !~ /^(ao|á|aos|ás|ó|ós)$/)
        return 2
      end
      # RULE: cara,X,cara,_	a,X,_,_,	_,_,_,ao|á|aos|ás|ó|ós,x
      if (window[0][0] =~ /^(cara)$/) and (window[0][1] =~ /^(X)$/) and (match_some_lemma(window[0][2], "cara")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(X)$/) and (window[2][3] =~ /^(ao|á|aos|ás|ó|ós)$/)
        return 3
      end
      # RULE: para,VIP3S,parar,_,x	_,PY*,_,_	_,VNP,_,_
      if (window[0][0] =~ /^(para)$/) and (window[0][1] =~ /^(VIP3S)$/) and (match_some_lemma(window[0][2], "parar")) and (window[1][1] =~ /^(PY.*)$/) and (window[2][1] =~ /^(VNP)$/)
        return 1
      end
      # RULE: non|aínda|que|se,_,_,_	_,V*,_,*mos	me,PY1S*,me,_	os,PY3MPA,o,_,x
      if (window[0][0] =~ /^(non|aínda|que|se)$/) and (window[1][1] =~ /^(V.*)$/) and (window[1][3] =~ /^(.*mos)$/) and (window[2][0] =~ /^(me)$/) and (window[2][1] =~ /^(PY1S.*)$/) and (match_some_lemma(window[2][2], "me")) and (window[3][0] =~ /^(os)$/) and (window[3][1] =~ /^(PY3MPA)$/) and (match_some_lemma(window[3][2], "o"))
        return 4
      end
      # RULE: nós,PY*,_,_	_,V*,_,*mos	me,PY1S*,me,_	os,PY3MPA,o,_,x
      if (window[0][0] =~ /^(nós)$/) and (window[0][1] =~ /^(PY.*)$/) and (window[1][1] =~ /^(V.*)$/) and (window[1][3] =~ /^(.*mos)$/) and (window[2][0] =~ /^(me)$/) and (window[2][1] =~ /^(PY1S.*)$/) and (match_some_lemma(window[2][2], "me")) and (window[3][0] =~ /^(os)$/) and (window[3][1] =~ /^(PY3MPA)$/) and (match_some_lemma(window[3][2], "o"))
        return 4
      end
      # RULE: _,PY*,_,_	_,V*,_,*mos	me,PY1S*,me,_	os,PY3MPA,o,_,x
      if (window[0][1] =~ /^(PY.*)$/) and (window[1][1] =~ /^(V.*)$/) and (window[1][3] =~ /^(.*mos)$/) and (window[2][0] =~ /^(me)$/) and (window[2][1] =~ /^(PY1S.*)$/) and (match_some_lemma(window[2][2], "me")) and (window[3][0] =~ /^(os)$/) and (window[3][1] =~ /^(PY3MPA)$/) and (match_some_lemma(window[3][2], "o"))
        return 4
      end
      # RULE: _,V*,_,*mos	me,PY1S*,me,_	os,PY3MPA,o,_,x	_,A0.P|VP.P|NC*|D*,_,_
      if (window[0][1] =~ /^(V.*)$/) and (window[0][3] =~ /^(.*mos)$/) and (window[1][0] =~ /^(me)$/) and (window[1][1] =~ /^(PY1S.*)$/) and (match_some_lemma(window[1][2], "me")) and (window[2][0] =~ /^(os)$/) and (window[2][1] =~ /^(PY3MPA)$/) and (match_some_lemma(window[2][2], "o")) and (window[3][1] =~ /^(A0.P|VP.P|NC.*|D.*)$/)
        return 3
      end
      # RULE: está,_,estar,_	me,PY1S*,me,_	os,PY3MPA,o,_,x	_,VGP,_,_	_,NC*|D*|PY*A0.P|VP.P|,_,_
      if (window[0][0] =~ /^(está)$/) and (match_some_lemma(window[0][2], "estar")) and (window[1][0] =~ /^(me)$/) and (window[1][1] =~ /^(PY1S.*)$/) and (match_some_lemma(window[1][2], "me")) and (window[2][0] =~ /^(os)$/) and (window[2][1] =~ /^(PY3MPA)$/) and (match_some_lemma(window[2][2], "o")) and (window[3][1] =~ /^(VGP)$/) and (window[4][1] =~ /^(NC.*|D.*|PY.*A0.P|VP.P|)$/)
        return 3
      end
      # RULE: está,_,estar,_	me,PY1S*,me,_	os,PY3MPA,o,_,x	_,_,en|ante|perante|diante,_
      if (window[0][0] =~ /^(está)$/) and (match_some_lemma(window[0][2], "estar")) and (window[1][0] =~ /^(me)$/) and (window[1][1] =~ /^(PY1S.*)$/) and (match_some_lemma(window[1][2], "me")) and (window[2][0] =~ /^(os)$/) and (window[2][1] =~ /^(PY3MPA)$/) and (match_some_lemma(window[2][2], "o")) and (match_some_lemma(window[3][2], "en|ante|perante|diante"))
        return 3
      end
      # RULE: Nós,Sp*,_,_,x	_,VI.10P,_,_
      if (window[0][0] =~ /^(Nós)$/) and (window[0][1] =~ /^(Sp.*)$/) and (window[1][1] =~ /^(VI.10P)$/)
        return 1
      end
      # RULE: Nós,Sp*,_,_,x	_,Wn,_,_	_,VI.1P,_,_
      if (window[0][0] =~ /^(Nós)$/) and (window[0][1] =~ /^(Sp.*)$/) and (window[1][1] =~ /^(Wn)$/) and (window[2][1] =~ /^(VI.1P)$/)
        return 1
      end
      # RULE: fora,W|X,fora,_,x	_,VP,_,_
      if (window[0][0] =~ /^(fora)$/) and (window[0][1] =~ /^(W|X)$/) and (match_some_lemma(window[0][2], "fora")) and (window[1][1] =~ /^(VP)$/)
        return 1
      end
      # RULE: _,D.MS,_,_,	aquel,D.MS,aquel,_,x
      if (window[0][1] =~ /^(D.MS)$/) and (window[1][0] =~ /^(aquel)$/) and (window[1][1] =~ /^(D.MS)$/) and (match_some_lemma(window[1][2], "aquel"))
        return 2
      end
      # RULE: _,DAFS,_,a,x	_,E*,_,_
      if (window[0][1] =~ /^(DAFS)$/) and (window[0][3] =~ /^(a)$/) and (window[1][1] =~ /^(E.*)$/)
        return 1
      end
      # RULE: _,V*,_,_,	_,PY*,_,se|o|os|a|as|nos,x	_,!V*|!PY*,_,_
      if (window[0][1] =~ /^(V.*)$/) and (window[1][1] =~ /^(PY.*)$/) and (window[1][3] =~ /^(se|o|os|a|as|nos)$/) and (window[2][1] !~ /^(V.*|!PY.*)$/)
        return 2
      end
      # RULE: *ei|*ou|*éi|óu,V*,_,_,	o|a|os|as,PY3*,o,o|a|os|as,x
      if (window[0][0] =~ /^(.*ei|.*ou|.*éi|óu)$/) and (window[0][1] =~ /^(V.*)$/) and (window[1][0] =~ /^(o|a|os|as)$/) and (window[1][1] =~ /^(PY3.*)$/) and (match_some_lemma(window[1][2], "o")) and (window[1][3] =~ /^(o|a|os|as)$/)
        return 2
      end
      # RULE: _,V*,estar|andar|ser|volver|comezar|empezar|chegar|vir|botar|poñer,_,	a,PY3FSA|DAFS,_,a,x	*ar|*er|*ir*|*or,V0*,_,_
      if (window[0][1] =~ /^(V.*)$/) and (match_some_lemma(window[0][2], "estar|andar|ser|volver|comezar|empezar|chegar|vir|botar|poñer")) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(PY3FSA|DAFS)$/) and (window[1][3] =~ /^(a)$/) and (window[2][0] =~ /^(.*ar|.*er|.*ir.*|.*or)$/) and (window[2][1] =~ /^(V0.*)$/)
        return 2
      end
      # RULE: ambos,PNMP,ambos,_,x	os,DAMP,o,_,	dous,_,_,_
      if (window[0][0] =~ /^(ambos)$/) and (window[0][1] =~ /^(PNMP)$/) and (match_some_lemma(window[0][2], "ambos")) and (window[1][0] =~ /^(os)$/) and (window[1][1] =~ /^(DAMP)$/) and (match_some_lemma(window[1][2], "o")) and (window[2][0] =~ /^(dous)$/)
        return 1
      end
      # RULE: ambas,PNFP,ambos,_,x	as,DAFP,o,_,	dúas,_,_,_
      if (window[0][0] =~ /^(ambas)$/) and (window[0][1] =~ /^(PNFP)$/) and (match_some_lemma(window[0][2], "ambos")) and (window[1][0] =~ /^(as)$/) and (window[1][1] =~ /^(DAFP)$/) and (match_some_lemma(window[1][2], "o")) and (window[2][0] =~ /^(dúas)$/)
        return 1
      end
      # RULE: con|de|en|entre|para|sen,X,_,_	_,VI*|VS*,_,_,x	me,_,_,_,	_,PY3*,_,_
      if (window[0][0] =~ /^(con|de|en|entre|para|sen)$/) and (window[0][1] =~ /^(X)$/) and (window[1][1] =~ /^(VI.*|VS.*)$/) and (window[2][0] =~ /^(me)$/) and (window[3][1] =~ /^(PY3.*)$/)
        return 2
      end
      # RULE: con|de|en|entre|para|sen,X,_,_	_,VI*|VS*,_,_,x	_,PY3*,_,!o|!a|!os|!as
      if (window[0][0] =~ /^(con|de|en|entre|para|sen)$/) and (window[0][1] =~ /^(X)$/) and (window[1][1] =~ /^(VI.*|VS.*)$/) and (window[2][1] =~ /^(PY3.*)$/) and (window[2][3] !~ /^(o|!a|!os|!as)$/)
        return 2
      end
      # RULE: non,_,_,_,	a,X,a,_,x	_,VI*|VS*|V0m*,_,_
      if (window[0][0] =~ /^(non)$/) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(X)$/) and (match_some_lemma(window[1][2], "a")) and (window[2][1] =~ /^(VI.*|VS.*|V0m.*)$/)
        return 2
      end
      # RULE: di,V*,dicir,día,x	a,PY3*,o,_,	tras|a,_,tras|a,tras|a,	día,NCMS,día,día,
      if (window[0][0] =~ /^(di)$/) and (window[0][1] =~ /^(V.*)$/) and (match_some_lemma(window[0][2], "dicir")) and (window[0][3] =~ /^(día)$/) and (window[1][0] =~ /^(a)$/) and (window[1][1] =~ /^(PY3.*)$/) and (match_some_lemma(window[1][2], "o")) and (window[2][0] =~ /^(tras|a)$/) and (match_some_lemma(window[2][2], "tras|a")) and (window[2][3] =~ /^(tras|a)$/) and (window[3][0] =~ /^(día)$/) and (window[3][1] =~ /^(NCMS)$/) and (match_some_lemma(window[3][2], "día")) and (window[3][3] =~ /^(día)$/)
        return 1
      end
      # RULE: noite,NCF,noite,noite,	e,C,e,e,	di,V*,dicir,día,x
      if (window[0][0] =~ /^(noite)$/) and (window[0][1] =~ /^(NCF)$/) and (match_some_lemma(window[0][2], "noite")) and (window[0][3] =~ /^(noite)$/) and (window[1][0] =~ /^(e)$/) and (window[1][1] =~ /^(C)$/) and (match_some_lemma(window[1][2], "e")) and (window[1][3] =~ /^(e)$/) and (window[2][0] =~ /^(di)$/) and (window[2][1] =~ /^(V.*)$/) and (match_some_lemma(window[2][2], "dicir")) and (window[2][3] =~ /^(día)$/)
        return 3
      end
      # RULE: di,V*,dicir,día,x	e,C,e,e,	noite,NCF,noite,noite
      if (window[0][0] =~ /^(di)$/) and (window[0][1] =~ /^(V.*)$/) and (match_some_lemma(window[0][2], "dicir")) and (window[0][3] =~ /^(día)$/) and (window[1][0] =~ /^(e)$/) and (window[1][1] =~ /^(C)$/) and (match_some_lemma(window[1][2], "e")) and (window[1][3] =~ /^(e)$/) and (window[2][0] =~ /^(noite)$/) and (window[2][1] =~ /^(NCF)$/) and (match_some_lemma(window[2][2], "noite")) and (window[2][3] =~ /^(noite)$/)
        return 1
      end
      # RULE: gustan|gusten|gustaban|gustarían,_,_,_	os,PY3MPA,o,_,x
      if (window[0][0] =~ /^(gustan|gusten|gustaban|gustarían)$/) and (window[1][0] =~ /^(os)$/) and (window[1][1] =~ /^(PY3MPA)$/) and (match_some_lemma(window[1][2], "o"))
        return 2
      end
      # RULE: vir,_,_,vila|vilas,x	_,PY3F.,_,_,	_,!VNP,_,_
      if (window[0][0] =~ /^(vir)$/) and (window[0][3] =~ /^(vila|vilas)$/) and (window[1][1] =~ /^(PY3F.)$/) and (window[2][1] !~ /^(VNP)$/)
        return 1
      end
      # RULE: cre,_,_,cremos,x	me,_,_,_,	_,PY3*,_,_,	que|en,_,_,_
      if (window[0][0] =~ /^(cre)$/) and (window[0][3] =~ /^(cremos)$/) and (window[1][0] =~ /^(me)$/) and (window[2][1] =~ /^(PY3.*)$/) and (window[3][0] =~ /^(que|en)$/)
        return 1
      end
      # RULE: cre,_,_,cremos,x	me,_,_,_,	_,PY3*,_,_,	_,VNP,_,_
      if (window[0][0] =~ /^(cre)$/) and (window[0][3] =~ /^(cremos)$/) and (window[1][0] =~ /^(me)$/) and (window[2][1] =~ /^(PY3.*)$/) and (window[3][1] =~ /^(VNP)$/)
        return 1
      end
      # RULE: como,_,_,_,	_,_,_,*mos,	me,_,_,_	_,PY3*,_,_,x
      if (window[0][0] =~ /^(como)$/) and (window[1][3] =~ /^(.*mos)$/) and (window[2][0] =~ /^(me)$/) and (window[3][1] =~ /^(PY3.*)$/)
        return 4
      end

      return 0
    end

    private

    def match_some_lemma (lemmas, string) = lemmas.any? { |l| l =~ /^(#{string})$/ }

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
  end
end
