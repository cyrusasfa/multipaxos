SRC_DIR = multipaxos
BEAM_DIR = multipaxos/ebin
MODULES = $(patsubst %.erl,%,$(shell ls $(SRC_DIR)/*.erl))

ERLC = erlc -o $(BEAM_DIR)
ERL = erl -noshell -pa ebin -setcookie pass

# ------------------------------------------------------------------------------

all: part_1 part_2

part_1:
	latexmk -pdf part_1.tex

part_2: erl system
	@echo $^

erl: ebin ${MODULES:%=%.beam}

ebin:
	@mkdir -p $(BEAM_DIR)

%.beam: %.erl
	$(ERLC) $?

clean:
	latexmk -C
	$(RM) *.bbl **/*.bbl *.run.xml **/*.run.xml
	$(RM) -r $(BEAM_DIR)

.PHONY: all clean part_1 part_2 erl

# ------------------------------------------------------------------------------

system:
	cd $(SRC_DIR) && $(ERL) -s system start
