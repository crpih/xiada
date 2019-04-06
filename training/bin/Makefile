all: clean galician_xiada

galician_xiada: galician_xiada_validate galician_xiada_escrita galician_xiada_oral galician_xiada_prensa galician_xiada_prensa_xeral galician_xiada_prensa_economia galician_xiada_relato

galician_xiada_validate:
	ruby validate_tags.rb ../corpus/galician_xiada/corpus_xiada.tagged ../corpus/galician_xiada/kernel/xiada_kernel.tags
	cat ../corpus/galician_xiada/corpus_xiada.tagged | ruby validate_all_fields.rb
	cd ../lexicons/bin; make galician_xiada_validate; cd ../../bin

galician_xiada_escrita:
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_escrita.tagged ../databases/galician_xiada/training_galician_xiada_escrita.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal_completado.txt
	cd ../lexicons/bin; make galician_xiada_escrita; cd ../../bin

galician_xiada_oral:
	ruby xiada_training.rb ../corpus/galician_xiada_oral/corpus_xiada_oral.tagged ../databases/galician_xiada_oral/training_galician_xiada_oral.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada_oral/lexicon_principal_completado_oral.txt
	cd ../lexicons/bin; make galician_xiada_oral; cd ../../bin

galician_xiada_prensa:
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_prensa.tagged ../databases/galician_xiada/training_galician_xiada_prensa.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal_completado.txt
	cd ../lexicons/bin; make galician_xiada_prensa; cd ../../bin

galician_xiada_prensa_xeral:
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_prensa_xeral.tagged ../databases/galician_xiada/training_galician_xiada_prensa_xeral.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal_completado.txt
	cd ../lexicons/bin; make galician_xiada_prensa_xeral; cd ../../bin

galician_xiada_prensa_economia:
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_prensa_economia.tagged ../databases/galician_xiada/training_galician_xiada_prensa_economia.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal_completado.txt
	cd ../lexicons/bin; make galician_xiada_prensa_economia; cd ../../bin

galician_xiada_relato:
	ruby xiada_training.rb ../corpus/galician_xiada/corpus_xiada_relato.tagged ../databases/galician_xiada/training_galician_xiada_relato.db ../corpus/galician_xiada/tags_info.txt ../lexicons/galician_xiada/lexicon_principal_completado.txt
	cd ../lexicons/bin; make galician_xiada_relato; cd ../../bin

clean:
	find .. -name "*~" | xargs rm -f
	rm -f ../databases/galician_xiada/*.db
	rm -f ../databases/galician_xiada_oral/*.db
