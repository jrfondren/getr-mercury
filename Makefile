MODULES=$(patsubst %.m,%,$(wildcard *.m))
GRADE=hlc.gc
OPT=-O6

all:: getr

clean::
	for x in $(MODULES); do rm -fv $$x.{err,mh,c_date,c,d,o}; done
	rm -rf Mercury
	rm -fv getr

getr: getr.m rusage.m spawn.m
	mmc $(OPT) --grade $(GRADE) --make $@