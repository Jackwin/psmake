#!/usr/bin/make -f
# SPDX-License-Identifier: Apache-2.0
#
################################################################################
##
## Copyright 2019 Missing Link Electronics, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
################################################################################
##
##  File Name      : Makefile
##  Initial Author : Stefan Wiehler <stefan.wiehler@missinglinkelectronics.com>
##
################################################################################
##
##  File Summary   : Scout convenience wrapper
##
##                   Uses: scout xsct
##
################################################################################

ifeq ($(XILINX_SCOUT),)
$(error XILINX_SCOUT is unset. This Makefile must be invoked from within a Scout environment)
endif

MAKEFILE_PATH := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

all: build

# include config
CFG ?= default
include $(CFG).mk

include $(MAKEFILE_PATH)common.mk

###############################################################################
# Variables

# platform project paths
HW_PLAT ?=
XPFM ?=

# user arguments, defaults, usually set via config.mk
DEF_DOMAIN_PROC ?= psu_cortexa53_0
DEF_DOMAIN_OS ?= standalone
DEF_APP_PROC ?= psu_cortexa53_0
DEF_APP_TMPL ?= Empty Application
DEF_APP_OS ?= standalone
DEF_APP_LANG ?= C
DEF_APP_BCFG ?= Release
DEF_APP_OPT ?= Optimize more (-O2)

DOMAIN_PRJS ?=
APP_PRJS ?=

# user arguments, rarely modified
PLAT_PRJ ?= plat
XSCT ?= xsct
SCOUT ?= scout

###############################################################################
# Platform repos

PLATS ?=

ifneq ($(strip $(PLATS)),)
__PLATS_CCMD = $(foreach PLAT,$(PLATS), \
	repo -add-platforms {$(PLAT)};)
endif

$(O)/.metadata/plats.stamp:
ifneq ($(strip $(PLATS)),)
	$(XSCT) -eval 'setws {$(O)}; $(__PLATS_CCMD)'
else
	mkdir -p $(O)/.metadata/
endif
	touch $@

###############################################################################
# Platform

# arg1: platform name
# arg2: path to platform file
define gen-plat-rule
$(O)/$(1)/_platform/dsa/$(1).stamp: $(O)/.metadata/repos.stamp $(O)/.metadata/plats.stamp
ifneq ($(HW_PLAT),)
	$(XSCT) -eval 'setws {$(O)}; \
		platform create -name {$(1)} -hw {$(2)}'
else
ifneq ($(XPFM),)
	$(XSCT) -eval 'setws {$(O)}; \
		platform create -name {$(1)} -xpfm {$(XPFM)}'
	touch $(O)/$(1)/xpfm.stamp
else
	@echo "error: missing HW_PLAT or XPFM, run either with HW_PLAT=<path-to-hw-platform> or XPFM=<path-to-xpfm>" >&2
	@false
endif
endif
	touch $$@

# shortcut to create platform, "make <plat>"
$(1): $(O)/$(1)/_platform/dsa/$(1).stamp
.PHONY: $(1)

$(1)_distclean:
	-$(XSCT) -eval 'setws {$(O)}; \
		platform remove -name {$(1)}'
.PHONY: $(1)_distclean
endef

###############################################################################
# System Configurations

# arg1: sysconfig name
# arg2: platform name
define gen-sysconfig-rule
$(O)/$(2)/_platform/$(1).stamp: $(O)/$(2)/_platform/dsa/$(2).stamp
	$(XSCT) -eval 'setws {$(O)}; \
		platform active {$(2)}; \
		sysconfig create -name {$(1)}'
	touch $$@

# shortcut to create sysconfig, "make <sysconfig>"
$(1): $(O)/$(2)/_platform/$(1).stamp
.PHONY: $(1)
endef

###############################################################################
# Domains

# arg1: domain name
# arg2: platform name
define gen-domain-rule
$(1)_SYSCONFIG ?= $(DEF_SYSCONFIG)
$(1)_PROC ?= $(DEF_DOMAIN_PROC)
$(1)_OS ?= $(DEF_DOMAIN_OS)
$(1)_LIBS ?=
$(1)_EXTRA_CFLAGS ?=
$(1)_STDIN ?=
$(1)_STDOUT ?=
$(1)_IS_FSBL ?=

ifneq ($$strip($$($(1)_LIBS)),)
__$(1)_LIBS_CCMD = $$(foreach LIB,$$($(1)_LIBS), \
	bsp setlib {$$(LIB)};)
endif
__$(1)_EXTRA_CCMD =
ifneq ($$($(1)_EXTRA_CFLAGS),)
__$(1)_EXTRA_CCMD += \
	bsp config extra_compiler_flags {$$($(1)_EXTRA_CFLAGS)};
endif
ifneq ($$($(1)_STDIN),)
__$(1)_EXTRA_CCMD += \
	bsp config stdin {$$($(1)_STDIN)};
endif
ifneq ($$($(1)_STDOUT),)
__$(1)_EXTRA_CCMD += \
	bsp config stdout {$$($(1)_STDOUT)};
endif
ifeq ($$($(1)_IS_FSBL),yes)
# non-default BSP settings for FSBL
__$(1)_EXTRA_CCMD += \
	bsp config {zynqmp_fsbl_bsp} {true}; \
	bsp config {read_only} {true}; \
	bsp config {use_mkfs} {false}; \
	bsp config {extra_compiler_flags} {-g -Wall -Wextra -Os -flto -ffat-lto-objects};
endif

$(O)/$(2)/_platform/$$($(1)_SYSCONFIG)/$(1)/bsp/Makefile: $(O)/$(2)/_platform/$$($(1)_SYSCONFIG).stamp
	$(XSCT) -eval 'setws {$(O)}; \
		platform active {$(2)}; \
		sysconfig active {$$($(1)_SYSCONFIG)}; \
		domain create -name {$(1)} -proc {$$($(1)_PROC)} \
			-os {$$($(1)_OS)}; \
		$$(__$(1)_LIBS_CCMD) \
		$$(__$(1)_EXTRA_CCMD) \
		$$($(1)_POST_CREATE_TCL)'

# One cannot apply patches/sed scripts on domains (BSPs) as in xsdk.mk;
# `platform generate` will override any modifications
$(O)/$(2)/export/$(2)/sw/$$($(1)_SYSCONFIG)/$(1)/lscript.ld: $(O)/$(2)/_platform/$$($(1)_SYSCONFIG)/$(1)/bsp/Makefile
	$(XSCT) -eval 'setws {$(O)}; \
		platform active {$(2)}; \
		platform generate'

# shortcut to create domain, "make <domain>"
$(1): $(O)/$(2)/export/$(2)/sw/$$($(1)_SYSCONFIG)/$(1)/lscript.ld
.PHONY: $(1)

$(1)_distclean:
	-$(XSCT) -eval 'setws {$(O)}; \
		platform active {$(2)}; \
		sysconfig active {$$($(1)_SYSCONFIG)}; \
		domain remove -name {$(1)}'
.PHONY: $(1)_distclean
endef

###############################################################################
# Applications

# arg1: app name
# arg2: platform name
define gen-app-rule
$(1)_SYSCONFIG ?= $$($$($(1)_DOMAIN)_SYSCONFIG)
$(1)_PROC ?= $(DEF_APP_PROC)
$(1)_TMPL ?= $(DEF_APP_TMPL)
$(1)_OS ?= $(DEF_APP_OS)
$(1)_LANG ?= $(DEF_APP_LANG)
$(1)_BCFG ?= $(DEF_APP_BCFG)
$(1)_OPT ?= $(DEF_APP_OPT)

ifneq ($$($(1)_HW),)
$(O)/$(1)/src/lscript.ld:
	$(XSCT) -eval 'setws {$(O)}; \
		app create -name {$(1)} -hw {$$($(1)_HW)} \
			-proc {$$($(1)_PROC)} -template {$$($(1)_TMPL)} \
			-os {$$($(1)_OS)} -lang {$$($(1)_LANG)}'
else
ifneq ($$($(1)_PLAT),)
$(O)/$(1)/src/lscript.ld: $(O)/.metadata/repos.stamp $(O)/.metadata/plats.stamp
	$(XSCT) -eval 'setws {$(O)}; \
		app create -name {$(1)} -platform {$$($(1)_PLAT)} \
			-sysconfig {$$($(1)_SYSCONFIG)} \
			-domain {$$($(1)_DOMAIN)} \
			-proc {$$($(1)_PROC)} -template {$$($(1)_TMPL)} \
			-os {$$($(1)_OS)} -lang {$$($(1)_LANG)}; \
		app config -name {$(1)} build-config {$$($(1)_BCFG)}; \
		app config -name {$(1)} compiler-optimization {$$($(1)_OPT)}'
else
$(O)/$(1)/src/lscript.ld: $(O)/$(2)/export/$(2)/sw/$$($(1)_SYSCONFIG)/$$($(1)_DOMAIN)/lscript.ld
	$(XSCT) -eval 'setws {$(O)}; \
		app create -name {$(1)} -platform {$(2)} \
			-sysconfig {$$($(1)_SYSCONFIG)} \
			-domain {$$($(1)_DOMAIN)} \
			-proc {$$($(1)_PROC)} -template {$$($(1)_TMPL)} \
			-os {$$($(1)_OS)} -lang {$$($(1)_LANG)}; \
		app config -name {$(1)} build-config {$$($(1)_BCFG)}; \
		app config -name {$(1)} compiler-optimization {$$($(1)_OPT)}'
endif
endif
ifneq ($$(strip $$($(1)_SRC)),)
	$$(foreach SRC,$$($(1)_SRC),$(call symlink-src,$(1),$$(SRC))) :
endif
ifneq ($$(strip $$($(1)_PATCH)),)
	$$(foreach PATCH,$$($(1)_PATCH),$(call patch-src,$(1)/src,$$(PATCH))) :
endif
ifneq ($$(strip $$($(1)_SED)),)
	$$(foreach SED,$$($(1)_SED),$(call sed-src,$(1)/src,$$(SED))) :
endif
# App project fails if patches/sed scripts have been applied and no clean has
# been performed
	$(XSCT) -eval 'setws {$(O)}; \
		app clean -name {$(1)}'

__$(1)_SRC = $(addprefix $(O)/$(1)/src/,$$($(1)_SRC))
$(O)/$(1)/$$($(1)_BCFG)/$(1).elf: $(O)/$(1)/src/lscript.ld $$(__$(1)_SRC)
	$(XSCT) -eval 'setws {$(O)}; \
		app build -name {$(1)}'

GEN_APPS_DEP += $(O)/$(2)/export/$(2)/sw/$$($(1)_SYSCONFIG)/$(1)/lscript.ld
BLD_APPS_DEP += $(O)/$(1)/$$($(1)_BCFG)/$(1).elf

# shortcut to create application, "make <app>"
$(1): $(O)/$(1)/$$($(1)_BCFG)/$(1).elf
.PHONY: $(1)

$(1)_distclean:
	-$(XSCT) -eval 'setws {$(O)}; \
		app remove {$(1)}'
.PHONY: $(1)_distclean

endef

###############################################################################
# Targets

# generate make rules for platform project, single
$(eval $(call gen-plat-rule,$(PLAT_PRJ),$(HW_PLAT)))
getdsa: $(PLAT_PRJ)
.PHONY: gethwplat

# generate make rules for system configurations, multiple
$(foreach DOMAIN_PRJ,$(DOMAIN_PRJS),\
	$(eval $(call gen-sysconfig-rule,$$($(DOMAIN_PRJ)_SYSCONFIG),$(PLAT_PRJ))))

# generate make rules for domains, multiple
$(foreach DOMAIN_PRJ,$(DOMAIN_PRJS),\
	$(eval $(call gen-domain-rule,$(DOMAIN_PRJ),$(PLAT_PRJ))))

# generate make rules for apps, multiple
$(foreach APP_PRJ,$(APP_PRJS),\
	$(eval $(call gen-app-rule,$(APP_PRJ),$(PLAT_PRJ))))

# generate make rules for bootgen projects, multiple
$(foreach BOOTGEN_PRJ,$(BOOTGEN_PRJS),\
	$(eval $(call gen-bif-rule,$(BOOTGEN_PRJ))))

# generate all projects
generate: $(GEN_APPS_DEP) $(GEN_BOOTGEN_DEP)
.PHONY: generate

# build all projects
build: $(BLD_APPS_DEP) $(BLD_BOOTGEN_DEP)
.PHONY: build

# open workspace in GUI mode
scout:
	$(SCOUT) -workspace $(O)
.PHONY: scout
