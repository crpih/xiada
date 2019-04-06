all: lexicon_principal_completado_oral

lexicon_principal_completado_oral:
	cat ../galician_xiada/lexicon_principal_completado.txt > lexicon_principal_completado_oral.txt
	ruby add_special_entries_oral.rb lexicon_principal_completado_oral.txt
	sort -u lexicon_principal_completado_oral.txt > tmp
	mv tmp lexicon_principal_completado_oral.txt

