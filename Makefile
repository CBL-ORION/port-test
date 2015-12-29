include make/helper.mk
include make/config.mk
include make/c-tap-harness-config.mk

TEST.c := $(shell find $(TESTDIR) -type f -name "*.c" -print)

TEST_PATHSUBST.c = $(patsubst $(TESTDIR)/%.c,$(BUILDTESTDIR)/%$(EXEEXT),$(1))
MKDIR_BUILDTESTDIR = mkdir -p `dirname $(call TEST_PATHSUBST.c,$<)`
TEST_OBJ := $(call TEST_PATHSUBST.c,$(TEST.c))


## Rules

all:
	echo "Success!"

dep: | dep.c-tap-harness dep dep.perl

dep.perl:
	cpanm --installdeps .

dep.c-tap-harness:
	./tool/external/c-tap-harness/download
	./tool/external/c-tap-harness/build

clean:
	-rm -Rf $(OUTPUT_DIRS)

test: $(TEST_OBJ)
	$(RUNTESTS) $(TEST_OBJ)
test: CPPFLAGS += $(TEST_CPPFLAGS)
test: LDFLAGS  += $(TEST_LDFLAGS)
test: LDLIBS   += $(TEST_LDLIBS)

$(BUILDTESTDIR)/%$(EXEEXT): $(TESTDIR)/%.c
	@$(MKDIR_DEPEND.c)
	@$(MKDIR_BUILDTESTDIR)
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@

dep.debian:
	sudo apt-get install --no-install-recommends $$( sed 's/#.*$$//g' < debian-packages )
