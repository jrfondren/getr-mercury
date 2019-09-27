MODULES=getr rusage spawn
DEPS=$(patsubst %,%.m,$(MODULES))
GRADE=hlc.gc
OPT=-O4 --intermodule-optimization

all:: getr

fork:: $(DEPS)
	mmc $(OPT) --grade $(GRADE) --cflags -DGETR_FORKEXEC --make getr

clean::
	for x in $(MODULES); do rm -fv $$x.{err,mh,c_date,c,d,o}; done
	rm -rf Mercury
	rm -fv getr

getr: $(DEPS)
	mmc $(OPT) --grade $(GRADE) --make $@
