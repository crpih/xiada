# CORGA client acceptance suite

`test/corga_document_test.rb` tests the **client's expectations**, not whether the
tagger reproduces a recorded error. `cases.json` preserves 44 documented cases;
31 are active acceptance cases. The nested section/subsection names follow
`odd/tasks/corga-xiada-client-annotation-cases.md`, excluding non-testable cases C3-01/C3-04,
C5-01, and sections 6 and 8. Thirteen O/A article-in-title cases remain
documented but deferred: their exact titles are absent from `lexicon_titulos`,
and adding those source entries is outside this task.
Hyphen/dash cases are not registered or generated at all while the client's
criterion is pending: there are no skipped placeholders for that section.
Failures are expected until the tagger satisfies the active requirements. Deferred
cases remain visible in `cases.json` but do not generate acceptance tests.

## Run

Use the existing databases from the repository root:

```sh
bundle exec ruby -Ilib:test test/corga_document_test.rb --verbose
```

A failing client case makes the command exit nonzero. Do not update a snapshot,
change the expected result to match the model, or fix production code merely to
make this synchronization green. Minitest randomizes execution; the full names
retain the document hierarchy and case IDs.

The assertion engine and fixture contracts have separate positive/negative
controls; a green result here does **not** mean the client cases pass:

```sh
bundle exec ruby -Ilib:test test/corga_document_contract_test.rb
```

## Outcomes and exclusions

| Outcome | Meaning |
|---|---|
| Pass | Public tagging output satisfies the stated client rule. |
| `CLIENT MISMATCH` | Actual segmentation, category, lemma or punctuation violates the client expectation. |
| `CLIENT EXPECTATION UNDEFINED` | The report does not define a defensible exact expectation. Explicit failure, not an omitted or passing test. |
| `CLIENT INPUT UNAVAILABLE` | C4-32 cannot execute without its obscured original title. Explicit failure, never a substitute input or a skip. |
| Deferred | Case remains documented but is excluded from active acceptance by an explicit scope decision. |

C3-01, C3-04 and C5-01 remain documented in the source report but are not tests:
the owner confirmed that the requested formula/superscript grouping is not
achievable and that the current representation is the best possible. The 34
section-6 hyphen cases remain in the source report and historical
snapshots, not in `cases.json` or generated tests. Section 8 is excluded while
the abbreviation experiment is postponed. The active suite has no skipped tests.

Four incomplete contracts remain explicit failures: C1-09, C2-01, C2-02 and
C4-32. Their messages explain the missing requirement or source. C1-13 now
requires only that `%` and the following comma be separate tokens; it does not
assert either token's tag or lemma. Available inputs are still tagged before an
undefined-expectation failure. No exact tag, source-code conversion or hidden
text is invented.

## Expectations and source context

- `cases.json` stores document headings, literal example/expected cells,
  independently specified `expectation` rules, input, focus and evidence scope.
- Lexical expectations for `€`, `ahum` and `de través` cite their lexical
  entries. C1-13 requires `%` and `,` as separate tokens without fixing their
  tags or lemmas. Abbreviation examples are excluded while that experiment is postponed.
- `Sp*` means a proper-name tag family, not a frozen `Sp00` subtype. C4-14,
  C4-19 and C4-21 require only the proper-name fragments recognized without
  title entries: `Aspeitos`, `Las` and `Pteridológicas de Galicia`. Full-title
  recognition requires a `lexicon_titulos` entry. C4-21 does not impose a new
  hyphen rule; C4-22 does not settle the pending boundary with `nº 17`.
- The 13 O/A article-in-title cases are deferred until their exact titles are
  registered in `lexicon_titulos`; the title entries are not maintained by this task.
- Ordinary periods have a legacy tokenization behavior: a period can remain
  attached to the preceding word (`palabra.`, `dubitativa.`). This is documented
  for a future correction; no tokenizer change is included now. T19 changes only
  proper-noun recognition after the point.
- C4-04/C4-05 keep their original source `input` and use `input_sentences` to
  model the upstream sentence boundary. The test helper tags those already
  segmented strings and maps token offsets back to the original input; it does
  not implement production sentence segmentation. A single combined input is
  covered by the ProperNouns unit tests and follows T19's proper-noun rule.
- C4-12/13/14 retain the full p050 sentence; C4-23–30 retain visible p061 context.
  Preceding text for A is recovered from p062; C4-34/35 use their corresponding
  full p050 sentence. Original source `infeción`/`no mundo` differs from the
  report's `infecion`/`en o mundo`; both spellings remain explicit in metadata.
- C4-37 remains a local diagnostic, not proof of a deployed search interface.
  Other excerpts retain their stated scope.
- C2-01 uses `galician_xiada_oral`; other available inputs use `galician_xiada`,
  with `seseo: true` and `gheada: true`. No database is rebuilt.

## Diagnostic snapshots are not acceptance

`baseline.json` (124 historical IDs) and `reviewed_baseline.json` (86-case prior
characterization) are preserved diagnostic artifacts. **Neither is loaded or
compared by the acceptance runner.** No baseline capture is needed to run it;
`UPDATE_SNAPSHOTS=1` cannot turn a client mismatch into a pass.

The legacy explicit diagnostic-capture entrypoint still refuses to overwrite
an existing snapshot. It is not the acceptance command:

```sh
bundle exec ruby -Ilib:test -r./test/support/corga_document -e 'exit CorgaDocument.capture'
```

Only the dedicated suite is run for this task: no global regression suite,
source/training changes, remote CORGA query, hyphen fixes, abbreviation
experiment or delivery operation. Follow `AGENTS.md` if execution moves to a worktree.
