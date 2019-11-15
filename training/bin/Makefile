all: clean galician_xiada spanish_eslora spanish_eslora_new

galician_xiada: clean_galician_xiada galician_xiada_escrita galician_xiada_oral galician_xiada_prensa galician_xiada_prensa_xeral galician_xiada_prensa_economia galician_xiada_relato

spanish_eslora: clean_spanish_eslora spanish_eslora_oral

spanish_eslora_new: clean_spanish_eslora spanish_eslora_oral_new

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

spanish_eslora_oral:
	ruby xiada_training.rb ../corpus/spanish_eslora/corpus_eslora.tagged ../databases/spanish_eslora/training_spanish_eslora.db ../corpus/spanish_eslora/tags_info.txt ../lexicons/spanish_eslora/lexicon_principal_completado.txt
	cd ../lexicons/bin; make spanish_eslora; cd ../../bin

spanish_eslora_oral_new:
	cat ../corpus/spanish_eslora/corpus_eslora.tagged | sed 's/fui\tVIS1S\tser/fui\tVIS1Sser\tser/;s/fuiste\tVIS2S\tser/fuiste\tVIS2Sser\tser/;s/fue\tVIS3S\tser/fue\tVIS3Sser\tser/;s/fuimos\tVIS1P\tser/fuimos\tVIS1Pser\tser/;s/fuísteis\tVIS2P\tser/fuísteis\tVIS2Pser\tser/;s/fueron\tVIS3P\tser/fueron\tVIS3Pser\tser/;s/fui\tVIS1S\tir/fui\tVIS1Sir\tir/;s/fuiste\tVIS2S\tir/fuiste\tVIS2Sir\tir/;s/fue\tVIS3S\tir/fue\tVIS3Sir\tir/;s/fuimos\tVIS1P\tir/fuimos\tVIS1Pir\tir/;s/fuisteis\tVIS2P\tir/fuisteis\tVIS2Pir\tir/;s/fueron\tVIS3P\tir/fueron\tVIS3Pir\tir/' > ../corpus/spanish_eslora/corpus_eslora_new.tagged
	cat ../lexicons/spanish_eslora/lexicon_principal_completado.txt | sed 's/fui\tVIS1S\tser/fui\tVIS1Sser\tser/;s/fuiste\tVIS2S\tser/fuiste\tVIS2Sser\tser/;s/fue\tVIS3S\tser/fue\tVIS3Sser\tser/;s/fuimos\tVIS1P\tser/fuimos\tVIS1Pser\tser/;s/fuísteis\tVIS2P\tser/fuísteis\tVIS2Pser\tser/;s/fueron\tVIS3P\tser/fueron\tVIS3Pser\tser/;s/fui\tVIS1S\tir/fui\tVIS1Sir\tir/;s/fuiste\tVIS2S\tir/fuiste\tVIS2Sir\tir/;s/fue\tVIS3S\tir/fue\tVIS3Sir\tir/;s/fuimos\tVIS1P\tir/fuimos\tVIS1Pir\tir/;s/fuisteis\tVIS2P\tir/fuisteis\tVIS2Pir\tir/;s/fueron\tVIS3P\tir/fueron\tVIS3Pir\tir/' | grep -v "VIS2Sser"> ../lexicons/spanish_eslora/lexicon_principal_completado_new.txt
	ruby xiada_training.rb ../corpus/spanish_eslora/corpus_eslora_new.tagged ../databases/spanish_eslora/training_spanish_eslora.db ../corpus/spanish_eslora/tags_info.txt ../lexicons/spanish_eslora/lexicon_principal_completado_new.txt
	cd ../lexicons/bin; make spanish_eslora; cd ../../bin

clean: clean_galician_xiada clean_spanish_eslora
	find .. -name "*~" | xargs rm -f

clean_galician_xiada:
	rm -f ../databases/galician_xiada/*.db
	rm -f ../databases/galician_xiada_oral/*.db

clean_spanish_eslora:
	rm -f ../databases/spanish_eslora/*.db
