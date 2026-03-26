all: proposal.pdf

proposal.tex: proposal.lhs.tex
	lhs2TeX proposal.lhs.tex > proposal.tex

proposal.pdf: proposal.tex local.bib dm.bib conferences.bib kaw.cls
	latexmk -xelatex proposal.tex

.PHONY: clean
clean:
	latexmk -C proposal.tex
	rm -f proposal.tex
