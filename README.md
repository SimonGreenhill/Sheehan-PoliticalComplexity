# Sheehan-PolComplex tree build

Builds a dated posterior tree set of D-PLACE **societies** from the global-language
EDGE phylogeny. The EDGE trees are indexed by Glottolog codes (one tip per language);
this pipeline grafts in missing languages, keeps only languages that map to a society,
expands each language tip into its societies, and dates society tips to their focal year.

## Requirements

BEAST2 (https://www.beast2.org) with the **Babel** package, which provides
`applauncher`. Two tools used here — `babel.tools.dplace.TaxonReplacer` and the
multi-height `TreeGrafter` — exist only in Babel git master
(https://github.com/rbouckaert/Babel), not the released package. See `build-babel.md`
for how they were compiled against the installed jars.

## Running

```bash
make            # build grafted.trees
make verify     # build, then check the taxon set matches dplace2.nxs
make clean      # remove intermediates and output
```

Reproducibility note: `TaxonReplacer` randomises internal node heights with no seed,
so a rebuild matches `dplace2.nxs` in taxa and topology but not byte-for-byte in
branch lengths. `TreeGrafter` is seeded (`SEED=127` in the Makefile).

## Pipeline

1. **Graft missing languages** — `TreeGrafter` adds 57 ancient, extinct, colonial and
   otherwise-missing languages onto the EDGE trees (`glotto_graft_map.cfg`) →
   `edge-grafted.trees`.
2. **Drop languages with no society** — `TaxonFilter` keeps only the 982 glottocodes
   listed in `glottocodes.dat` → `glotto.trees` → `glotto.nxs`.
3. **Expand to societies** — `TaxonReplacer` replaces each language tip with its
   society sub-tree (`glotto2society.dat`) and dates the tips to their focal year
   (`society_id-focal_year.tsv`) → `dplace.trees` → `dplace.nxs`.
4. **Fix xd1128** — `TaxonFilter` drops the mis-placed society xd1128 (keeping the
   1126 taxa in `xd1128-keep.dat`), then `TreeGrafter` grafts it back above xd1130 at
   age 0.18 (`graft-xd1128.cfg`) → `dplace2.trees`.

`soc2label.dat` / `label2soc.dat` support relabelling society ids to human-readable
names (via Babel `TreeRelab`) when producing summary trees; the Makefile does not use them.

## Files

### Build / docs
| File | Role |
|------|------|
| `Makefile` | Reproducible, path-free build of the tree set |
| `build-babel.md` | How the missing Babel tools were compiled and installed |

### Inputs
| File | Role |
|------|------|
| `global-language-trees-6636-taxa.trees` | Source EDGE tree set, 6636 tips, bare glottocodes |
| `glotto_graft_map.cfg` | Grafts for missing languages: `glottocode`, height, comma-separated attachment codes |
| `glottocodes.dat` | The 982 glottocodes that have an associated society |
| `glotto2society.dat` | `glottocode` → society, or `(xd..,xd..)` sub-tree of societies |
| `society_id-focal_year.tsv` | `society_id` → focal year, used as the tip date |
| `xd1128-keep.dat` | Societies to keep when removing/re-grafting xd1128 (1126 ids) |
| `soc2label.dat` | `society_id` → human-readable label (name, glottocode, family) for summary trees |
| `label2soc.dat` | Inverse of `soc2label.dat` (label → id) |

### Generated (removed by `make clean`)
| File | Role |
|------|------|
| `edge-grafted.trees` | Step 1 output: EDGE + 57 grafted languages |
| `glotto.trees` / `glotto.nxs` | Step 2 output: 982 language tips (Newick / Nexus) |
| `dplace.trees` / `dplace.nxs` | Step 3 output: society tips, focal-year dated |
| `graft-xd1128.cfg` | Generated one-line graft config for xd1128 |
| `dplace-xd1128.trees` / `.nxs` | Step 4: xd1128 removed |
| `dplace2.trees` | Step 4: xd1128 grafted back — the final tree set |
| `grafted.trees` | The Makefile's built output (final tree set) |

### Reference
| File | Role |
|------|------|
| `dplace2.nxs` | Result of the original `dplace.sh` run; `make verify` compares against it |


## AI Disclosure

Claude Opus 4.8 was used to construct the Makefile pipeline for reproducibility only. All other code and scripts were human created.
