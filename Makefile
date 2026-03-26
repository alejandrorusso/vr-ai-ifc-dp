all: proposal.pdf

proposal.pdf: proposal.lhs.tex biblio kaw.cls
	lhs2TeX proposal.lhs.tex > proposal.tmp
	xelatex proposal.tmp
	bibtex proposal
	xelatex proposal.tmp
	xelatex proposal.tmp
	rm proposal.tmp

biblio: local.bib dm.bib conferences.bib

.PHONY: clean
clean:
	rm -f *.aux *.bbl *.log *.blg *.out *.pdf *.ptb proposal.tmp
