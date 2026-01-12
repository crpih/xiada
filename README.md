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

## Usage

Build docker image and start service

```bash
bin/build
cp profiles.example.yml profiles.yml # copy default profiles. You can edit and remove the ones you don't need for faster startup.
docker compose up -d
```

Building may take a while since it trains the tagger.

## Configuration

Relevant environment variables for tagger configuration:

- XIADA_PROFILE: Name of the profile to use.
- XIADA_DATABASE: Name of the database to use.
- XIADA_ONLY_LEXICON: If true, only lexicon will be used to tag the text.
- XIADA_FORCE_PROPER_NOUNS: If true, all capitalized words will be tagged as proper nouns.

Supported combinations of these variables are defined in `profiles.yml` file.

### API requests

Then you can send requests like:

```bash
curl --request POST \
  --url 'http://localhost:4000/tagger?profile=galician_xiada&database=galician_xiada_escrita&only_lexicon=false&force_proper_nouns=false' \
  --header 'Content-Type: application/json' \
  --data '[
	"Texto de proba."
]'
```

Configuration parameters are passed as URL query parameters.

### Interactive usage

```bash
docker compose exec -e XIADA_PROFILE=galician_xiada -e XIADA_DATABASE=galician_xiada_escrita tagger ruby running/bin/xiada_tagger.rb
```

Then write text and press enter to get tagged output. Configuration parameters are passed as environment variables.

## Testing

Ruby and some native libraries are required to run tests. Check the Dockerfile for reference about required packages and ruby version.

### Execute all tests

```bash
bundle # Install dependencies
bin/build-host-train # Build image training in local machine
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

Uncomment relevant line in regression tests to save current results as reference.
