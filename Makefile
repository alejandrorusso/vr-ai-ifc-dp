all: proposal.pdf pub.pdf

proposal.pdf: proposal.tex local.bib dm.bib conferences.bib kaw.cls
	latexmk -xelatex -shell-escape proposal.tex

pub.pdf: pub.tex russo.bib kawcv.cls
	latexmk -xelatex pub.tex

.PHONY: clean
clean:
	latexmk -C proposal.tex
	latexmk -C pub.tex
