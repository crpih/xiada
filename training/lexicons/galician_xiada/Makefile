all: lexicon_principal_completado

lexicon_principal_completado:
	cat lexicon_abreviaturas.txt lexicon_cliticos.txt lexicon_locucions_inseguras.txt lexicon_locucions_seguras.txt lexicon_numerais_cardinais.txt lexicon_principal.txt lexicon_propios.txt lexicon_siglas.txt > lexicon_principal_completado.txt
	ruby add_special_entries.rb lexicon_principal_completado.txt
	sort -u lexicon_principal_completado.txt > tmp
	mv tmp lexicon_principal_completado.txt