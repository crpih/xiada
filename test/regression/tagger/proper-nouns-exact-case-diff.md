# Manual tagger snapshot diffs: exact-case guard

Captured only `galician_xiada_escrita_manual_cases` after the exact-case guard change. The harness was minimally extended so `UPDATE_SNAPSHOTS=1` can write this corpus while retaining the pre-existing CORGA update behavior. No other corpus was regenerated.

The first attempted filter, `--name=/galician_xiada_regressions_manually_selected/`, matched no tests (0 runs, exit 1). The actual Minitest names contain the snapshot corpus name; rerunning with `--name=/galician_xiada_escrita_manual_cases/` selected all 25 corpus examples and passed (25 runs, 25 assertions, 0 failures). The snapshots below are compared to committed `HEAD` bytes.

## Observed exact diffs by effect

Rows use the snapshot's four tab-separated columns: `token / tag / lemma / hiperlemma`. `""` is the literal empty value as serialized in CSV.

### Proper-noun and boundary-analysis changes

**Snapshot 1 — input:** `Coa película 'Parque Xurásico', o director e productor`

```diff
-Parque\tScms\tparque\tparque
-Xurásico\tSp00\tXurásico\t""
+Parque Xurásico\tSp00\tParque Xurásico\t""
```

**Snapshot 8 — input:** `Ora, non é menos certo que en ambos os casos achamos, por unha banda, como hai un importante sentimento de pertenza á Terra, digámolo así, conceptualizada por cada quen dun ou doutro xeito _Patria, Rexión, etc_ e, por outra, observamos como hai unha vontade superadora dunha situación de subdesenvolvemento desa Terra propia, manifestada singularmente na construción dun forte tecido escolar _o que nos fala implicitamente da idea/imaxe que aqueles emigrantes tiñan sobre si e arredor dunha Galiza atrasada;`

```diff
-Patria\tScfs\tpatria\tpatria
+Patria\tSp00\tPatria\t""
-Rexión\tSpm0\tRexión\t""
+Rexión\tSp00\tRexión\t""
```

This is an observed side effect worth reviewing: exact-case proper-name-looking words in a lexicon context can change from a common/inflected lexical analysis to a proper-noun analysis. In particular, the semantic rule proposed for the feature can suppress exact-case proper names that already exist in the lexicon (including the `Xoán` / `Galicia` concern recorded during prior work); do not infer from these snapshot rows that those examples are covered here. Unit expectations already changed around that semantic choice. The exact spelling does not itself ensure unchanged tokenization/analysis in every context.

**Snapshots 20 and 21 — inputs:**

- 20: `petróleo Non a guerra. Non podemos.`
- 21: `petróleo Non a guerra. Non embargante, Bebel era unha excepción.`

Both show the same changed rows:

```diff
-guerra.\tZafs\t*\t*
-Non\tWn\tnon\tnon
+guerra\tScfs\tguerra\tguerra
+.\tQ.\t.\t.
+Non\tSp00\tNon\t""
```

### Other observed token/tag/lemma/hiperlemma diffs in this corpus

These are recorded exactly, but not attributed causally to the exact-case guard by assertion alone.

**Snapshot 0 — input:** `EE UU`

```diff
-EE UU\tZg00\tEE UU\tEE. UU.
+EE UU\tZg00\tEE UU\tEE UU
```

**Snapshot 22 — input:** `van a estar en A Coruña xunto con Luís Veira <pausa/> o chef <pausa/> Michelín de Árbore da Veira <pausa/> do restaurante da Coruña <pausa/> e gustaríanos ehh`

```diff
-<pausa/>\tZf00\t*\t*
+<pausa/>\tZs00\t*\t*
-chef\tScms\t*\t*
-<pausa/>\tZf00\t*\t*
-Michelín de Árbore\tSp00\tMichelín de Árbore\t""
+chef\tScms\tchef\tchef
+<pausa/>\tZs00\t*\t*
+Michelín de Árbore\tSpms\tMichelín de Árbore\t""
-<pausa/>\tZf00\t*\t*
+<pausa/>\tScms\t*\t*
-<pausa/>\tZf00\t*\t*
+<pausa/>\tScms\t*\t*
```

**Snapshot 23 — input:** `entraba en o porto con a monteira de través e tocando a gaita en a proa.`

```diff
-de través\tWn\tde través\tde través
+de\tP\tde\tde
+través\tWn\t*\t*
```

## Changed snapshot paths

Exactly seven committed snapshot files were modified:

- `test/regression/tagger/galician_xiada_escrita_manual_cases/0.csv`
- `test/regression/tagger/galician_xiada_escrita_manual_cases/1.csv`
- `test/regression/tagger/galician_xiada_escrita_manual_cases/8.csv`
- `test/regression/tagger/galician_xiada_escrita_manual_cases/20.csv`
- `test/regression/tagger/galician_xiada_escrita_manual_cases/21.csv`
- `test/regression/tagger/galician_xiada_escrita_manual_cases/22.csv`
- `test/regression/tagger/galician_xiada_escrita_manual_cases/23.csv`

## Verification

- `UPDATE_SNAPSHOTS=1 bundle exec ruby -Ilib:test test/regression/tagger/xiada_tagger_test.rb --name=/galician_xiada_regressions_manually_selected/`: no matching tests, 0 runs, exit 1; no snapshots were written by that attempt.
- `UPDATE_SNAPSHOTS=1 bundle exec ruby -Ilib:test test/regression/tagger/xiada_tagger_test.rb --name=/galician_xiada_escrita_manual_cases/`: 25 runs, 25 assertions, 0 failures, 0 errors, 0 skips.
- `ruby -rcsv -e 'CSV.foreach("test/regression/tagger/galician_xiada_escrita_manual_cases.csv", col_sep: "\t", skip_lines: /^#/, skip_blanks: true).each_with_index { |row, i| puts "#{i}: #{row.first.inspect}" if [0,1,8,20,21,22,23].include?(i) }'`: observed source input text for every changed index.

No larger regression or full-suite run was part of this snapshot-capture step. Snapshot diffs are data, not behavior-level tests; test-first RED/GREEN is not applicable to this authorized data capture.

## Full-corpus snapshot capture

During the authorized full capture, the test harness temporarily allowed snapshot writes for any corpus when `UPDATE_SNAPSHOTS == "1"`. After capture, the write block was commented out so future runs only compare and never overwrite snapshots. The authorized capture passed all 1,867 examples and assertions. Compared with `HEAD`, 55 existing snapshot files changed: 41 Galician reference, 7 manual (the seven listed above), 7 CORGA 4.2, and 0 Spanish Eslora. No new numbered snapshot was needed; the four corpus directories already existed. The Spanish corpus produced no snapshot diffs.

Final harness state: snapshot writing code is commented out in `xiada_tagger_test.rb`. The regression suite passed 1,867/1,867 both with `UPDATE_SNAPSHOTS` unset and with `UPDATE_SNAPSHOTS=1`; the aggregate snapshot hash was identical before and after the latter run. Two CORGA capitalization expectations were updated to the new proper-noun analyses. The last full repository run before those expectation updates reported three additional Galician lemmatizer failures; the full suite was not rerun after updating the two expected CORGA outputs.

Rows below are the exact changed snapshot rows; columns are `token / tag / lemma / hiperlemma`, and `""` denotes an empty serialized value. Each item gives the matching source input. Grouping describes observed output only; except where a row plainly changes token boundaries, causal attribution to a specific rule is **unproven** from this diff alone.

### Galician reference — proper-noun analysis or multi-token proper-name changes

- **1075.csv** — input: `Colgáranlle que bautizara a un can seguindo o ritual católico do sacramento, póndolle dous nomes, un legal para empregar en público e que era "Negrillo", e outro secreto, que sóio llo chamaba na casa ou entre xente de confianza, e que era "San Pablo".` `Negrillo / Scms / negrillo / negrillo` → `Negrillo / Sp00 / Negrillo / ""`. Observed proper-noun promotion; cause unproven.
- **1128.csv** — input: `É "Dos hombres contra el oeste".` `Dos / Scmp / don / don` → `Dos / Sp00 / Dos / ""`. Observed proper-noun promotion; cause unproven.
- **12.csv** — input: `Viste de alivio e protéxese da luz cunha pucha raida co lema "Percebeiros do Roncudo.` `Percebeiros / A0mp / percebeiro / percebeiro` → `Percebeiros / Sp00 / Percebeiros / ""`. Observed proper-noun promotion; cause unproven.
- **1210.csv** — input: `Baixo o título de 'Halos', que acaba de ver a luz na colección Galician Classics _promovida pola Xunta de Galicia e Small Station Press_.` `Halos / Scmp / halo / halo` → `Halos / Sp00 / Halos / ""`. Observed proper-noun promotion; cause unproven.
- **1238.csv** — input: `Pola súa banda a produtora non confirmou nin desmentiu nada e incluso chegou a insinuar que a película podía ser pasada polo filtro zombie e facer unha especie de remake da 'Benvidos á fin do mundo' (The world's end) pero con zombies, tartarugas ninja e transformers.` `Benvidos / A0mp / benvido / benvido` → `Benvidos / Spfs / Benvidos / ""`. Observed proper-noun analysis and tag change; cause unproven.
- **1372.csv** — input: `Foi un dos fundadores do grupo literario e galeguista Brais Pinto e escribiu máis dun cento de artigos sobre o cine, ademáis de publicar obras poéticas (Acoitelado na espera) e novelas curtas (Un hombre llega al cine e Bajo el puente).` `Acoitelado / V0p0ms / acoitelar / acoitelar` → `Acoitelado / Sp00 / Acoitelado / ""`; `Un / Dims / un / un` → `Un / Sp00 / Un / ""`. Both observed proper-noun promotions; cause unproven.
- **138.csv** — input: `Fig. 2.1. Debuxo utilizado como polo Museo de Pontevedra.` `debuxo / Scms / debuxo / debuxo` → `Debuxo / Sp00 / Debuxo / ""`. Observed case/token and proper-noun change; cause unproven.
- **1519.csv** — input: `Catálogo da exposición bibliográfica (Círculo de las Artes de Lugo, 1964).` `Círculo / Spms / Círculo / ""` + `de / P / de / de` + `las / Ddfp / o / ""` + `Artes de Lugo / Spfp / Artes de Lugo / ""` → `Círculo de las Artes de Lugo / Sp00 / Círculo de las Artes de Lugo / ""`. Proper-name merging observed; cause unproven.
- **1534.csv** — input: `Un profesor meu nesta facultade díxome un día que a Medicina é "Bioloxía práctica", técnicas biolóxicas, e as "Ciencias Médicas" non existen.` `Ciencias / Scfp / ciencia / ciencia` + `Médicas / Sp00 / Médicas / ""` → `Ciencias Médicas / Spfp / Ciencias Médicas / ""`. Proper-name merging observed; cause unproven.
- **239.csv** — input: `_A transposición da directiva europea 2007/02/EC para establecer unha Infraestrutura de Información Espacial na Comunidade Europea (Directiva INSPIRE) que ten como obxectivo obter información actualizada sobre o estado do territorio para a toma de decisións.` `Directiva / Scfs / directiva / directiva` → `Directiva / Sp00 / Directiva / ""`. Observed proper-noun promotion; cause unproven.
- **284.csv** — input: `Non se trata dunha adiviña senón dun ciclo de conferencias co lema de Italia, unha oportunidade para Galicia, ciclo auspiciado polo Instituto Español de Comercio Exterior e polo IGAPE (Instituto Galego de Promoción Económica).` `Instituto / Spms / Instituto / ""` + `Galego de Promoción Económica / Sp00 / Galego de Promoción Económica / ""` → `Instituto Galego de Promoción Económica / Sp00 / Instituto Galego de Promoción Económica / ""`. Proper-name merging observed; cause unproven.
- **307.csv** — input: `O estigma da enfermidade cae sobre personaxes tan relevantes como Santa Catalina de Siena ou escritores entrañables como Kafka, que no seu "Artista famento" non fai máis que describi-la súa propia experiencia patolóxica.` `Artista / Scms / artista / artista` → `Artista / Spms / Artista / ""`. Observed proper-noun promotion; cause unproven.
- **532.csv** — input: `A Sociedade Galega do Medio Ambiente (Sogama), co apoio da Consellería de Medio Ambiente, Territorio e Infraestruturas, presentou a súa candidatura á convocatoria de axudas lanzada o pasado mes de maio pola Comisión Europea, no marco do instrumento financeiro dedicado ao medio ambiente Life+, dentro da modalidade de Información e Comunicación.` `medio / A0ms / medio / medio` + `ambiente / Scms / ambiente / ambiente` → `medio ambiente / Scms / medio ambiente / medio ambiente`; `Life / Spms / Life / ""` → `Life / Sp00 / Life / ""`. Multiword lexical segmentation and proper-noun tag change observed; cause unproven.
- **57.csv** — input: `Na remodelación das súas tendas, iniciada hai meses para darlle máis protagonismo á area de ofertas (Alcampo non ten unha segunda marca para tendas de menor prezo, caso do Carrefour (Dia) ou Eroski (Familia)), a compañía decidiu prescindir do galego.` `Dia / Scms / dia / día` → `Dia / Sp00 / Dia / ""`. Observed proper-noun promotion; cause unproven.
- **611.csv** — input: `Tanto a canción como o vídeo están baseados en 'Aquel excitante curso' ('Fast Times at Ridgemont High'), o filme de 1982 de Cameron Crowe.` `Aquel / Enms / aquel / aquel` → `Aquel / Sp00 / Aquel / ""`. Observed proper-noun promotion; cause unproven.
- **647.csv** — input: `Seguramente agora a túa mente diga "Ah!` `Ah / Y / ah / ah` → `Ah / Sp00 / Ah / ""`. Observed proper-noun promotion; cause unproven.
- **704.csv** — input: `_A terra Chá luguesa. Estudio da súa problemática agraria. Ed. O Castro, Coruña, 1982.` `luguesa. / Za00 / * / *` → `luguesa / A0fs / lugués / lugués` + `. / Q. / . / .`; `Estudio / Scms / estudio / estudio` → `Estudio / Sp00 / Estudio / ""`. Sentence punctuation segmentation and proper-noun analysis observed; cause unproven.
- **743.csv** — input: `Nela converxen Campus do Mar (universidades de Vigo, Santiago e A Coruña), Campus Mare Nostrum (Murcia e Politécnica de Cartagena), Campus Atlántico Tricontinental (Las Palmas e La Laguna) e CEI-MAR (Cádiz, Málaga, Huelva, Almería e Granada).` `Las / Ddfp / o / ""` + `Palmas / Spfp / Palmas / ""` → `Las Palmas / Sp00 / Las Palmas / ""`. Proper-name merging observed; cause unproven.
- **962.csv** — input: `Esta última, coñecida como "Ruta Esmeralda", é a máis importante das tres.` `Ruta / Scfs / ruta / ruta` + `Esmeralda / Sp00 / Esmeralda / ""` → `Ruta Esmeralda / Sp00 / Ruta Esmeralda / ""`. Proper-name merging observed; cause unproven.
- **1651.csv** — input: `Sobre o teatro de enorme saibo popular e expresivo de Lope de Rueda (nomeadamente os 'Pasos').` `Pasos / Scmp / paso / paso` → `Pasos / Spmp / Pasos / ""`. Observed proper-noun promotion/tag change; cause unproven.
- **1656.csv** — input: `Os obxectivos de Abert@s, amosados na xornada de datos ceibes do CPEIG.` `CPEIG / Zgfs / * / *` → `CPEIG / Zgms / CPEIG / CPEIG`. Tag/lemma/hiperlemma changed; cause unproven.
- **1657.csv** — input: `Os obxectivos de Abertos, amosados na xornada de datos ceibes do CPEIG.` `CPEIG / Zgfs / * / *` → `CPEIG / Zgms / CPEIG / CPEIG`. Tag/lemma/hiperlemma changed; cause unproven.

### Galician reference — lexical tag, lemma, or hiperlemma changes (not assigned a cause)

- **1060.csv** — input: `A semellanza é só ilusoria e a través da reiteración baleiramos o significado, achamos o neutro, non para momificar (o que sucedía ao repetir o mesmo), senón para crear, para proliferar cualitativa e indefinidamente (o que sucede ao insistir na repetición da diferenza).` `só / Wm / só / ""` → `só / Wm / só / só`. Other hiperlemma value; cause unproven.
- **210.csv** — input: `É só sostible para as grandes empresas financeiras e fondos de investimento, que se están a beneficiar da crise, rendibilizando os seus capitais...` `só / Wm / só / ""` → `só / Wm / só / só`. Hiperlemma value; cause unproven.
- **1190.csv** — input: `51º Rali Príncipe de Asturias-Ciudad de Oviedo.` `rali / Scms / * / *` → `rali / Scms / rali / rally`.
- **1310.csv** — input: `Mentres a guerra en Chechenia se propaga, as tropas rusas "continúan atacando, matando, saqueando e torturando a civís", segundo denuncia nun recente informe a organización de defensa dos dereitos humanos Human Rights Watch, que critica ó Goberno de EE UU e á ONU pola súa "pasividade".` `civís / A0mp / civil / civil` → `civís / Scfp / civil / civil`.
- **1322.csv** — input: `Pola súa parte, o portavoz de Xustiza do PP, Federico Trillo, acudirá hoxe ó Xuzgado de Instrucción número 43 de Madrid para ratificar a denuncia presentada polo PP pola presunta utilización delictiva dos fondos reservados no período 1987-1994, aportando incluso testemuñas e indicios do suposto uso ilícito no Ministerio do Interior.` `reservados / A0mp / reservado / reservado` → `reservados / V0p0mp / reservar / reservar`.
- **1335.csv** — input: `Cristina Alberdi presidiu un acto público contra o racismo e en defensa das minorías que orgaizaban os Jóvenes contra la Intolerancia, con motivo do Día Internacional da Loita contra o Racismo.` `orgaizaban / Vii30p / * / *` → `orgaizaban / Vii30p / orgaizar / organizar`.
- **148.csv** — input: `Ao cabo dise plazo, o silencio súpeto e longo despertou a Antón que dormía, encollido, escrequenado, en riba dun metro cadrado de taboas de caixón.` `taboas / Scfp / táboas / táboas` → `taboas / Scfp / táboa / táboa`.
- **1560.csv** — input: `Para que ninguén se perda, o xogo conta cun completo e aclarador titorial, xunto cun curioso axuste especial: opción para persoas que padezan daltonismo.` `aclarador / A0ms / * / *` → `aclarador / A0ms / aclarador / aclarador ` (the new hiperlemma includes a trailing space).
- **1687.csv** — input: `O Master dunha producción leva na signatura, despois da letra do bloque temático, a letra M entre paréntesis, o mesmo número da producción que o orixinou, dous puntos, e o(s) tempo(s) da(s) video-cassette(s) que o forman.` `paréntesis / Scfs / * / *` → `paréntesis / Scfs / paréntesis / paréntese`.
- **917.csv** — input: `Se ben a desgusto, o xefe do pequeno fato de guerrilleiros do que formaba parte meu irmán, cedeu a retesía de Carlos e autorizou aquela desaxocada aventura que meu irmán quería derrancar soio, pero que a parella dos seus íntimos amigos, agora presentes na cociña da nosa casa, derrancaron con el, sendo sabedores do moito perigo que ofrecía, o ter que actuar nunha zona medio urbán e moi vixiada polas forzas que os seus nemigos chamaban do orde, cunha poboación non concienciada, e nunha boa parte, oposta os seus ideais.` `nemigos / Scmp / * / *` → `nemigos / Scmp / nemigo / inimigo`.
- **929.csv** — input: `¡Virás comigo ao reino das Tebras!` `virás / Vfi20s / vir / vir` → `virás / A0mp / viral / viral`.

### Galician reference — additional proper-name/abbreviation values

- **333.csv** — input: `Xosé Manuel Pazos Varela (PSdeG) propúxolle ó partido no poder que lle dese o seu apoio á comisión de investigación, igual que en Madrid co caso do liño, para "demostrar que non hai irregularidades".` `PSdeG / Zg00 / PSdeG / ""` → `PSdeG / Zg00 / PSdeG / PSdeG`. Hiperlemma change; cause unproven.
- **385.csv** — input: `O secretario xeral do Partido Socialista de Galicia (PSdeG) Emilio Pérez Touriño, apelou onte á unidade de tódolos demócratas a favor da liberdade e da vida para combate-la violencia da banda terrorista ETA e establecer unha fronteira sólida similar á que se conseguiu durante a Transición, onde tódolos demócratas estaban nunha beira e na outra os terroristas e a dictadura.` `PSdeG / Zg00 / PSdeG / ""` → `PSdeG / Zg00 / PSdeG / PSdeG`. Hiperlemma change; cause unproven.
- **533.csv** — input: `Pola súa banda, o secretario xeral do PSdeG, Manuel Vázquez, dixo que a súa formación irá aos xulgados se a Xunta mantén a pretensión de elaborar o catálogo, que suporía "reducir os dereitos farmacéuticos dos pensionistas e dos enfermos galegos".` `PSdeG / Zgms / PSdeG / ""` → `PSdeG / Zgms / PSdeG / PSdeG`. Hiperlemma change; cause unproven.
- **859.csv** — input: `O PSdeG escenificou onte a súa nova estrutura, coa foto oficial da nova Executiva que, liderada por Manuel "Pachi" Vázquez, pretende afrontar unha oposición cuxo cometido será chegar, dentro de catro anos, a que o socialismo galego obteña o apoio nas urnas de al menos un 40% do electorado.` `PSdeG / Zgms / PSdeG / ""` → `PSdeG / Zgms / PSdeG / PSdeG`. Hiperlemma change; cause unproven.
- **885.csv** — input: `O Tribunal Europeo de Dereitos Humanos condenou onte a España a indemnizar con 23.000 euros a Aritz Beristain Ukar por non investigar os malos tratos denunciados polo demandante tras a súa detención o 5 de setembro de 2002 por actos de kale borroka (violencia nas rúas).` `kale / A0fs / * / *` + `borroka / Scfs / * / *` → `kale borroka / Scfs / kale borroka / kale borroka`. Multiword segmentation observed; cause unproven.

### Galician reference — tokenization/segmentation and punctuation changes

- **1359.csv** — input: `Un voceiro da policía local informou onte de que o detido, R.Ch. Ch, de 34 anos, secuestrou a punta de escopeta de caza ó xefe do grupo, cando se atopaba en compañía doutras dúas persoas no lugar coñecido como as Siete Fuentes, a dous quilómetros do centro urbano.` `R.Ch. / Za00 / * / *` + `Ch / Scms / ch / ch` → `R.Ch / Y / * / *` + `. / Q. / . / .` + `Ch / Sp00 / Ch / ""`. Splitting punctuation and changed analysis both observed; cause unproven.
- **1542.csv** — input: `Pasa a rente de bares nos que hai risas e animación.` `a / Ddfs / o / o` + `rente / Scfs / * / *` + `de / P / de / de` → `a rente de / P / a rente de / a rentes de`. Multiword segmentation observed; cause unproven.

- **1561.csv** — input: `Coeficientes (<fórmula/> erro estandar) da ecuación (4.02) de axuste da variabilidade da clorofila (Chl a), en <fórmula/>, nas cinco Rías Altas.` First `<fórmula/> / Zf00 / <fórmula/> / ""` → `<fórmula/> / Zs00 / * / *`; later `<fórmula/> / Zf00 / <fórmula/> / ""` → `<fórmula/> / Scms / * / *`. Other placeholder/tag changes; cause unproven.

### CORGA 4.2 — exact changed rows

- **0.csv** — input: `Na devandita pancarta podíanse le-los lemas 'Infraestructuras e emprego para o noso futuro' e 'Móvete pola traza costeira da Transcantábrica'.` `Infraestructuras / Scfp / infraestructura / infraestrutura` → `Infraestructuras / Sp00 / Infraestructuras / ""`. Proper-noun promotion observed; cause unproven.
- **1.csv** — input: `O primeiro deles foi presentado tamén en 2004 pola Consellería de Política Territorial co título Avance das Directrices de Ordenación do Territorio (no que segue citaremos DOT) que rotula o seu terceiro capítulo como "Infraestruturas e modelo territorial", con subapartados diferenciados para ferrocarrís e para portos.` `DOT / Zg00 / * / *` → `DOT / Zg00 / DOT / DOT`; `Infraestruturas / Scfp / infraestrutura / infraestrutura` → `Infraestruturas / Sp00 / Infraestruturas / ""`. One lexicon analysis promotion plus one proper-noun abbreviation value change; cause unproven.
- **10.csv** — input: `Neste eido cabería resaltar a implicación dalgúns grupos no entendemento da ecoloxía dentro da globalidade e o seu compromiso coa solidariedade, coa denuncia do militarismo, coa cooperación que levaron a algúns dos grupos da FEG a involucrarse en proxectos paralelos como puido ser o nacemento da Coordinadora Galega de ONGD,s, ou a Coordinadora de Agricultura Ecolóxica de Galicia, mesmo a tentativa da creación do primeiro banco ecolóxico galego baixo o nome de ABSE (Asociación para a Banca Social e Ecolóxica), a vinculación ao movemento ciclousuario na ConBici da que en Galiza organízanse os Encontros de ciclousuarios de toda a Península Ibérica,` `FEG / Zgfs / * / *` → `FEG / Zgfs / FEG / FEG`; `ABSE / Zg00 / * / *` → `ABSE / Zg00 / ABSE / ABSE`; `Asociación / Scfs / asociación / asociación` → `Asociación / Sp00 / Asociación / ""`. Proper-noun/lexicon-value changes observed; cause unproven.
- **4.csv** — input: `Vázquez: "Somos duros de roer"` `Somos / Vpi10p / ser / ser` → `Somos / Sp00 / Somos / ""`. Observed proper-noun promotion; cause unproven.
- **5.csv** — input: `Todos nós sabemos o que 'Abella' significa.` `Abella / Vpi30s / abellar / abellar` → `Abella / Sp00 / Abella / ""`. Observed proper-noun promotion; cause unproven.
- **7.csv** — input: `Desde Erguer. Estudantes da Galiza formúlase como o posíbel vehículo non só para outorgar ao país capacidade lexisladora propia en materia de ensino, senón tamén para colocar as primeiras pedras dalgunhas das mudanzas estruturais máis necesarias no actual sistema educativo.` `Estudantes / Scmp / estudante / estudante` → `Estudantes / Sp00 / Estudantes / ""`. Observed proper-noun promotion; cause unproven.
- **9.csv** — input: `A almibarada Miley Cyrus _Hannah Montana_ ponlle cordas vocais á coprotagonista.` `almibarada / A0fs / * / *` → `almibarada / A0fs / almibarado / almibarado`. Lexical lemma/hiperlemma value changed; cause unproven.

### Corpus counts and causality

| Corpus | Changed snapshot files | Observed scope |
|---|---:|---|
| Galician reference | 41 | Proper-noun analyses, lexical tag/lemma/hiperlemma values, and segmentation/punctuation; see entries above. |
| Manual selected | 7 | Retained in the earlier exact-case comparison above. |
| CORGA 4.2 | 7 | Proper-noun/abbreviation analyses and lexical values; see entries above. |
| Spanish Eslora | 0 | No changed snapshots. |

These are output deltas after the behavior change, not proofs of individual rule causality. In particular, proper-noun promotions and merged names are observed effects; without tracing the precise rule and token context for each row, their causes remain unproven. No source behavior or database was changed as part of this capture.
