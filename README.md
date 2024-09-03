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

1. Install sqlite3:

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



## Build docker image

./build.sh

Tagger is trained and generated databases are copied inside the image.
Por 4000 is exposed.

`XIADA_PROFILE` and `XIADA_DATABASE` must be defined to run the container. 

### Running the server

```bash
docker run -e XIADA_PROFILE=galician_xiada -e XIADA_DATABASE=galician_xiada_escrita -p 4000:4000 xiada_tagger
```

### Tag a simple text

```bash
docker run -ti -e XIADA_PROFILE=galician_xiada -e XIADA_DATABASE=galician_xiada_escrita xiada_tagger ruby running/bin/xiada_tagger.rb
```

## Testing

### Execute all tests

```bash
bundle exec rake test
```

### Execute all tests for one profile:

```
bundle exec ruby -I"lib:test" test/regression/tagger/xiada_tagger_test.rb --name="/spanish_eslora/
```

### Execute only a test

Specify file and test name as a regular expression. Example execute only the ESLORA regression test of `1.xml` file:

```bash
bundle exec ruby -I"lib:test" test/regression/tagger/xiada_tagger_test.rb --name="/spanish_eslora.*_1.xml/"
```

### Save tests results for reference

Define the environment variable `XIADA_SAVE_RESULT=1` and execute tests.
