# XIADA: Tagger/Lemmatizer for Galician Language

XIADA is an statistical POS tagger based on Markov models and developed with ruby language. It treats XML documents natively, which allows anybody to tag XML documents in an easy way.

At present, the tagger includes three different custom configurations:

1. galician_xiada

    To tag and lemmatize Galician written texts.

1. galician_xiada_oral

    To tag and lemmatize Galician spoken transcriptions.

1. spanish_eslora

    To tag and lemmatize Spanish spoken transcriptions.

galician_xiada corpora and configurations come from [CORGA](http://corpus.cirp.gal/corga) project, while spanish_eslora ones come from [ESLORA](http://eslora.usc.es) project. You can find more information about authoring and licensing on the corresponding directories.

## Project home page

http://corpus.cirp.gal/xiada

## INSTALL

1. Install ruby (> 2.5.0 version):

    Our preferred way is through [rbenv](https://github.com/rbenv/rbenv)/[ruby-build](https://github.com/rbenv/ruby-build).

1. Intall bundler

        gem install bundler

1. Install libpgdm3 and sqlite3:

    In Debian stable:

        sudo apt-get install libsqlite3-0 libsqlite3-dev sqlite3 sqlite3-dev

1. Clone the repo:

        git clone git@github.com:crpih/xiada.git

1. Install required gems:

    Enter repo root directory (from now on `repo_root_directory`) and run:

        bundle install

## TRAIN

  The tagger can be trained entering `repo_root_directory` and then run:

### for Galician XIADA...

    cd training/bin
    make galician_xiada

### for Spanish ESLORA...

    cd training/bin
    make spanish_eslora

This command will generate different training databases in `repo_root_directory/training/databases` (it will take several minutes to finish).

## CHECK

To check that all is working fine, from `repo_root_directory` run:

    bundle exec rake test

## RUN

And, finally, the tagger can be launched in several ways. Here is an example:

### Tag sentences inside an XML document

First, XIADA_PROFILE environment variable must be set:

#### for written Galician XIADA...

    export XIADA_PROFILE="galician_xiada"

#### for spoken Galician XIADA...

    export XIADA_PROFILE="galician_xiada_oral"

#### for spoken Spanish ESLORA...

    export XIADA_PROFILE="spanish_eslora"

An xml file (named, for example, `input.xml`) like this one could be created, replacing the sentence content as needed:

#### for written Galician XIADA...

    <?xml version="1.0" encoding="UTF-8"?>
    <documento>
      <oración>Esta é unha oración de exemplo para probar.</oración>
      <oración>Esta é outra oración</oración>
    </documento>

#### for spoken Galician XIADA...

    <?xml version="1.0" encoding="UTF-8"?>
    <documento>
      <fragmento>Esta é unha oración de exemplo para probar.</fragmento>
      <fragmento>Esta é outra oración</gragmento>
    </documento>

#### for spoken Spanish ESLORA...

    <?xml version="1.0" encoding="UTF-8"?>
    <documento>
      <oración>Esta es una oración de ejemplo para probar.</oración>
      <oración>Esta es otra oración.</oración>
    </documento>

And the command to tag the file could be:

#### for written Galician XIADA...

    ruby running/bin/xiada_tagger.rb -v -x running/galician_xiada/xml_values.txt -f input.xml training/databases/galician_xiada/training_galician_xiada_escrita.db 

#### for spoken Galician XIADA...

    ruby running/bin/xiada_tagger.rb -v -x running/galician_xiada_oral/xml_values.txt -f input.xml training/databases/galician_xiada_oral/training_galician_xiada_oral.db

#### for spoken Spanish ESLORA...

    ruby running/bin/xiada_tagger.rb -v -x running/spanish_eslora/xml_values.txt -f input.xml training/databases/spanish_eslora/training_spanish_eslora.db 

The output will be sent to STDOUT, so you can redirect it to another xml file:

#### for written Galician XIADA...

    ruby running/bin/xiada_tagger.rb -v -x running/galician_xiada/xml_values.txt -f input.xml training/databases/galician_xiada/training_galician_xiada_escrita.db > output.xml

#### for spoken Galician XIADA...

    ruby running/bin/xiada_tagger.rb -v -x running/galician_xiada_oral/xml_values.txt -f input.xml training/databases/galician_xiada_oral/training_galician_xiada_oral.db > output.xml

#### for spoken Spanish ESLORA...

    ruby running/bin/xiada_tagger.rb -v -x running/spanish_eslora/xml_values.txt -f input.xml training/databases/spanish_eslora/training_spanish_eslora.db > output.xml 
    
Or, as the output of the tagger is not very nice (it is not indented), we use to pass the output through `xmllint` program this way:

#### for written Galician XIADA

    ruby running/bin/xiada_tagger.rb -v -x running/galician_xiada/xml_values.txt -f input.xml training/databases/galician_xiada/training_galician_xiada_escrita.db | xmllint --format - > output.xml

#### for spoken Galician XIADA...

    ruby running/bin/xiada_tagger.rb -v -x running/galician_xiada_oral/xml_values.txt -f input.xml training/databases/galician_xiada_oral/training_galician_xiada_oral.db | xmllint --format - > output.xml

#### for spoken Spanish ESLORA...

    ruby running/bin/xiada_tagger.rb -v -x running/spanish_eslora/xml_values.txt -f input.xml training/databases/spanish_eslora/training_spanish_eslora.db | xmllint --format - > output.xml

## Build docker image

Build image with:

```bash
DOCKER_BUILDKIT=1 docker build --ssh default -t xiada_tagger-eslora:latest .

DOCKER_BUILDKIT=1 docker build --ssh default -t xiada_tagger-corga:latest .
```

Existing training databases are copied inside the image.
Por 4000 is exposed.
`XIADA_PROFILE` must be defined to run the container. 

## Testing

### Execute all tests

```bash
bundle exec rake test
```

### Execute only a test

Specify file and test name as a regular expression. Example execute only the ESLORA regression test of `1.xml` file:

```bash
bundle exec ruby -I"lib:test" test/regression/tagger/xiada_tagger_test.rb --name="/spanish_eslora.*_1.xml/"
```

### Save tests results for reference

Define the environment variable `XIADA_TESTS_RESULTS=1` and execute tests.
