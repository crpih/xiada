# XIADA: Tagger/Lemmatizer for Galician Language

XIADA is an statistical POS tagger based on Markov models and developed with ruby language. It treats XML documents natively, which allows anybody to tag XML documents in an easy way.

## INSTALL

1. Install ruby (> 2.0 version):

    Our preferred way is through [rbenv](https://github.com/rbenv/rbenv)/[ruby-build](https://github.com/rbenv/ruby-build).

1. Intall bundler

        gem install bundler

1. Install libpgdm3 and sqlite3:

    In Debian stable:

        sudo apt-get install libgdbm3 libgdbm-dev libsqlite3-0 libsqlite3-dev sqlite3 sqlite3-dev

1. Clone the repo:

        git clone https://github.com/rbenv/ruby-build.git

1. Install required gems:

    Enter repo root directory (`repo_root_directory`) and run:

        bundle install

## TRAIN

  The tagger can be trained entering `repo_root_directory` and then run:

        cd training/bin
        make all

  This command will generate different training databases in `repo_root_directory/training/databases` (it will take several minutes to finish).

## CHECK

To check that all is working fine, from `repo_root_directory` run:

    rake test

## RUN

And, finally, the tagger can be launched in several ways. Here is an example:

### Tag sentences inside an XML document

An xml file (named, for example, `input.xml`) like this one could be created, replacing the sentence content as needed:

    <?xml version="1.0" encoding="UTF-8"?>
    <documento>
      <oración>Esta é unha oración de exemplo para probar.</oración>
      <oración>Esta é outra oración</oración>
    </documento>

And the command to tag the file could be:

    ruby running/bin/xiada_tagger.rb -v -x running/galician_xiada/xml_values.txt -f input.xml training/databases/galician_xiada/training_galician_xiada_escrita.db 

The output will be sent to STDOUT, so you can redirect it to another xml file:

    ruby running/bin/xiada_tagger.rb -v -x running/galician_xiada/xml_values.txt -f input.xml training/databases/galician_xiada/training_galician_xiada_escrita.db > output.xml 

Or, as the output of the tagger is not very nice (it is not indented), we use to pass the output through `xmllint` program this way:

    ruby running/bin/xiada_tagger.rb -v -x running/galician_xiada/xml_values.txt -f input.xml training/databases/galician_xiada/training_galician_xiada_escrita.db | xmllint --format - > output.xml
