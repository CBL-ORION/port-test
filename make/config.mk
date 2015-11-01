## Config

ORION_PATH ?= ../orion
ORION3_MAT_PATH ?= ../orion/external/orion3mat

ifeq ($(call TEST_DIR_EXIST,$(ORION_PATH)),FALSE)
    $(info Need to set the ORION_PATH to the root of the ORION project directory:)
    $(info $(TABMARK)make ORION_PATH="/path/to/orion")
    $(error Missing ORION dependency.)
endif

BUILDTESTDIR := build
TESTDIR := test

OUTPUT_DIRS := $(BUILDTESTDIR)
