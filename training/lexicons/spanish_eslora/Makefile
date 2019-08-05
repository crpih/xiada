all: construir_principal_completado

construir_principal_completado:
# abreviaturas are not used in eslora project
	cat lexicon_principal.txt lexicon_siglas.txt | ruby filtering.rb | sort -u > lexicon_principal_completado.txt
	ruby add_special_entries.rb lexicon_principal_completado.txt
