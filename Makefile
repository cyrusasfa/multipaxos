all: part_1

part_1:
	latexmk -pdf part_1.tex

clean:
	latexmk -C
	$(RM) *.bbl **/*.bbl *.run.xml **/*.run.xml

.PHONY: all clean
