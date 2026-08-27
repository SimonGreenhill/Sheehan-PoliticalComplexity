# Makefile: build the dplace tree set from the global-language EDGE tree.
#
# Reproduces the pipeline in dplace.sh as a self-contained, path-free build:
# every config/data file lives in this directory (no CFG env var, no ~ paths).
#
# Requires BEAST2 with the Babel package, providing `applauncher`. The pipeline
# uses babel.tools.dplace.TaxonReplacer and the multi-height TreeGrafter, which
# exist only in Babel git master (https://github.com/rbouckaert/Babel) - not in
# the released package. See build-babel target / README for how these were
# compiled in.  treeannotator is not needed: dplace2.nxs is a raw tree set.
#
# NOTE on reproducibility: TaxonReplacer randomises internal node heights and
# exposes no seed, so grafted.trees matches dplace2.nxs in taxa and topology but
# NOT byte-for-byte in branch lengths. TreeGrafter IS seeded (SEED below).
#
# Usage:
#   make            # build grafted.trees
#   make verify     # build, then compare taxon set/count against dplace2.nxs
#   make clean      # remove generated intermediates and output

# --- inputs -----------------------------------------------------------------
SRC      := global-language-trees-6636-taxa.trees    # EDGE tree set (bare glottocodes)
GRAFTMAP := glotto_graft_map.cfg                     # ancient/extinct/colonial grafts
GLOTTO   := glottocodes.dat                          # glottocodes that have a society
G2S      := glotto2society.dat                       # glottocode -> society sub-tree
FOCAL    := society_id-focal_year.tsv                # society -> focal year (tip date)
KEEP     := xd1128-keep.dat                          # societies to keep (all but xd1128)

APP      := applauncher
SEED     := 127                                      # seed for TreeGrafter steps


.PHONY: all verify clean
all: grafted.trees

# Step 1: graft in ancient, extinct, colonial and otherwise missing languages
#         (adds 57 taxa; lati1261 uses a sampled height, hence -seed)
edge-grafted.trees: $(SRC) $(GRAFTMAP)
	$(APP) TreeGrafter -cfg $(GRAFTMAP) -tree $(SRC) -out $@ -seed $(SEED)

# Step 2: drop taxa whose glotto-code has no associated society (leaves 982 taxa)
glotto.trees: edge-grafted.trees $(GLOTTO)
	$(APP) TaxonFilter -subset $(GLOTTO) -trees edge-grafted.trees -out $@

glotto.nxs: glotto.trees
	$(APP) Newick2Nexus -trees glotto.trees -out $@

# Step 3: replace glottocode tips with society sub-trees and set tip dates to
#         focal times for dplace societies
dplace.trees: glotto.nxs $(G2S) $(FOCAL)
	$(APP) TaxonReplacer -times $(FOCAL) -cfg $(G2S) -tree glotto.nxs -out $@ -maxTime 1.0

dplace.nxs: dplace.trees
	$(APP) Newick2Nexus -trees dplace.trees -out $@

# Step 4: remove xd1128 (mis-placed) then graft it back above xd1130 at age 0.18
graft-xd1128.cfg:
	printf 'xd1128\t0.18\txd1130\n' > $@

dplace-xd1128.trees: dplace.nxs $(KEEP)
	$(APP) TaxonFilter -subset $(KEEP) -trees dplace.nxs -out $@

dplace-xd1128.nxs: dplace-xd1128.trees
	$(APP) Newick2Nexus -trees dplace-xd1128.trees -out $@

dplace2.trees: dplace-xd1128.nxs graft-xd1128.cfg
	$(APP) TreeGrafter -cfg graft-xd1128.cfg -tree dplace-xd1128.nxs -out $@ -minTime 1.0 -seed $(SEED)

$(OUT): dplace2.trees
	$(APP) Newick2Nexus -trees dplace2.trees -out $@

# --- checks -----------------------------------------------------------------
# verify taxon set: count + sorted labels must be identical to dplace2.nxs.
verify: grafted.trees dplace2.nxs
	@echo "reference: $$(grep -m1 ntax dplace2.nxs)"
	@echo "built    : $$(grep -m1 ntax grafted.trees)"
	@sed -n '/Taxlabels/,/;/p' dplace2.nxs | grep -oE 'xd[0-9a-z]+' | sort -u > /tmp/ref_taxa.txt
	@sed -n '/Taxlabels/,/;/p' grafted.trees      | grep -oE 'xd[0-9a-z]+' | sort -u > /tmp/out_taxa.txt
	@if diff -q /tmp/ref_taxa.txt /tmp/out_taxa.txt >/dev/null; then \
		echo "OK: taxon set is identical to dplace2.nxs ($$(wc -l < /tmp/out_taxa.txt | tr -d ' ') taxa)"; \
	else \
		echo "MISMATCH: taxon set differs from dplace2.nxs"; \
		diff /tmp/ref_taxa.txt /tmp/out_taxa.txt | head; exit 1; \
	fi

clean:
	rm -f edge-grafted.trees glotto.trees glotto.nxs \
	      dplace.trees dplace.nxs graft-xd1128.cfg \
	      dplace-xd1128.trees dplace-xd1128.nxs dplace2.trees grafted.trees
