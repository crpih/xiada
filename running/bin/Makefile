all: compile_galician_xiada_rules compile_galician_xiada_oral_rules compile_spanish_eslora_rules
compile_galician_xiada_rules:
	cat enclitics_processor.base.rb | ruby enclitic_verbs_rules_compiler.rb ../galician_xiada/enclitic_verbs_rules.xml | ruby enclitic_pronouns_rules_compiler.rb ../galician_xiada/enclitic_pronouns_rules.xml > ../galician_xiada/enclitics_processor.rb
	cat ../galician_xiada/pruning_rules.txt | ruby pruning_rules_compiler.rb > ../galician_xiada/pruning_system.rb
compile_galician_xiada_oral_rules:
	cat enclitics_processor.base.rb | ruby enclitic_verbs_rules_compiler.rb ../galician_xiada/enclitic_verbs_rules.xml | ruby enclitic_pronouns_rules_compiler.rb ../galician_xiada/enclitic_pronouns_rules.xml > ../galician_xiada_oral/enclitics_processor.rb
	cat ../galician_xiada/pruning_rules.txt | ruby pruning_rules_compiler.rb > ../galician_xiada_oral/pruning_system.rb
compile_spanish_eslora_rules:
	cat enclitics_processor.base.rb | ruby enclitic_verbs_rules_compiler.rb ../spanish_eslora/enclitic_verbs_rules.xml | ruby enclitic_pronouns_rules_compiler.rb ../spanish_eslora/enclitic_pronouns_rules.xml > ../spanish_eslora/enclitics_processor.rb
	cat ../spanish_eslora/pruning_rules.txt | ruby pruning_rules_compiler.rb > ../spanish_eslora/pruning_system.rb
compile_tagset_evaluation_rules:
	cat enclitics_processor.base.rb | ruby enclitic_verbs_rules_compiler.rb ../tagset_evaluation/enclitic_verbs_rules.xml | ruby enclitic_pronouns_rules_compiler.rb ../tagset_evaluation/enclitic_pronouns_rules.xml > ../tagset_evaluation/enclitics_processor.rb
	cat ../tagset_evaluation/pruning_rules.txt | ruby pruning_rules_compiler.rb > ../tagset_evaluation/pruning_system.rb
