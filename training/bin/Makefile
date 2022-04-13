all: clean galician_xiada spanish_eslora

galician_xiada: clean_galician_xiada galician_xiada_escrita galician_xiada_oral galician_xiada_prensa galician_xiada_prensa_xeral galician_xiada_prensa_economia galician_xiada_relato

spanish_eslora: clean_spanish_eslora spanish_eslora_oral

tagset_evaluation: clean_tagset_evaluation tagset_evaluation_default

galician_xiada_escrita:
	rm -f ../databases/galician_xiada/training_galician_xiada_escrita.db
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_escrita.tagged ../databases/galician_xiada/training_galician_xiada_escrita.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal.txt
	cd ../lexicons/bin; make galician_xiada_escrita; cd ../../bin

galician_xiada_oral:
	ruby xiada_training.rb ../corpus/galician_xiada_oral/corpus_xiada_oral.tagged ../databases/galician_xiada_oral/training_galician_xiada_oral.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada_oral/lexicon_principal.txt
	cd ../lexicons/bin; make galician_xiada_oral; cd ../../bin

galician_xiada_prensa:
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_prensa.tagged ../databases/galician_xiada/training_galician_xiada_prensa.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal.txt
	cd ../lexicons/bin; make galician_xiada_prensa; cd ../../bin

galician_xiada_prensa_xeral:
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_prensa_xeral.tagged ../databases/galician_xiada/training_galician_xiada_prensa_xeral.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal.txt
	cd ../lexicons/bin; make galician_xiada_prensa_xeral; cd ../../bin

galician_xiada_prensa_economia:
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_prensa_economia.tagged ../databases/galician_xiada/training_galician_xiada_prensa_economia.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal.txt
	cd ../lexicons/bin; make galician_xiada_prensa_economia; cd ../../bin

galician_xiada_relato:
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_relato.tagged ../databases/galician_xiada/training_galician_xiada_relato.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal.txt
	cd ../lexicons/bin; make galician_xiada_relato; cd ../../bin

spanish_eslora_oral:
	ruby xiada_training.rb ../corpus/spanish_eslora/corpus_eslora.tagged ../databases/spanish_eslora/training_spanish_eslora.db ../corpus/spanish_eslora/tags_info.txt ../lexicons/spanish_eslora/lexicon_principal.txt
	cd ../lexicons/bin; make spanish_eslora; cd ../../bin

tagset_evaluation_default:
	ruby xiada_training.rb ../corpus/tagset_evaluation/corpus_tagset_evaluation.tagged ../databases/tagset_evaluation/training_tagset_evaluation.db ../corpus/tagset_evaluation/tags_info.txt ../lexicons/tagset_evaluation/lexicon_principal.txt
	cd ../lexicons/bin; make tagset_evaluation; cd ../../bin

clean: clean_galician_xiada clean_spanish_eslora
	find .. -name "*~" | xargs rm -f

clean_galician_xiada:
	rm -f ../databases/galician_xiada/*.db
	rm -f ../databases/galician_xiada_oral/*.db

clean_spanish_eslora:
	rm -f ../databases/spanish_eslora/*.db

clean_tagset_evaluation:
	rm -f ../databases/tagset_evaluation/*.db
