<!--
# SPDX-License-Identifier: Apache-2.0
#
################################################################################
##
## Copyright 2018-2019 Missing Link Electronics, Inc.
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
##  File Name      : README.md
##  Initial Author : Stefan Wiehler <stefan.wiehler@missinglinkelectronics.com>
##
################################################################################
-->

# Processing System Makefiles

This repository bundles convenience Makefiles for developing software targeting
the embedded processors of SoC FPGAs or soft cores embedded in a programmable
logic (PL) design – so called Processing Systems (PS). It features the
following components:

* PetaLinux wrapper Makefile
* Xilinx Software Development Kit (XSDK) convenience Makefile


## PetaLinux Wrapper Makefile

`petalinux.mk` is a Makefile for PetaLinux projects. It acts as convenience
wrapper script around the PetaLinux toolchain and adds additional
functionality.


### Supported Platforms

PetaLinux is supported from v2018.1 to v2019.1 (i.e. the last four releases).
The Makefile should run on all underlying OSs supported by PetaLinux; however
testing is only conducted on Ubuntu 18.04 LTS (Bionic Beaver) as of now.


### Setup

In your PetaLinux project directory, create a symlink named `Makefile` to the
`petalinux.mk` file:

    $ ln -s ../scripts/petalinux.mk Makefile

Then, execute:

    $ make HDF=<path-to-your-hdf>

to import a Hardware Description File (HDF) and build the PetaLinux project.


### Usage

The following Makefile targets are provided:

`gethdf`
: Initialize the project with a Hardware Description File (HDF). You must
provide a HDF via the `HDF` variable.

`config`
: Configure system-level options.

`config-kernel`
: Configure the Linux kernel.

`config-rootfs`
: Configure the root filesystem.

`build` (default)
: Build the system.

`sdk`
: Build the Software Development Kit (SDK).

`package-boot`
: Package boot image. You can provide different binaries from the default ones
for bitstream, FSBL, ATF, PMU firmware and U-Boot via the `BIT`, `FSBL`, `ATF`,
`PMUFW` and `UBOOT` variables, respectively. To skip packaging FSBL, ATF or PMU
firmware, set the respective variable to `no`. Additional boot arguments can be
specified with `BOOT_ARG_EXTRA`; run `petalinux-package --boot --help` for a
list of options. The output path can be changed with the `BOOT` variable.

`package-prebuilt`
: Copy built artifacts to pre-built directory.

`package-bsp`
: Package Board Support Package (BSP). The BSP file name must be given with the
`BSP` variable.

`dts`
: Decompile the device tree.

`reset-jtag`
: Reset board via JTAG. The hardware server URL must be provided via the
`HW_SERVER_URL` variable.

`boot-jtag-u-boot`
: Boot board into U-Boot via JTAG. The hardware server URL must be provided via
the `HW_SERVER_URL` variable.

`boot-jtag-kernel`
: Boot board and upload Linux kernel via JTAG. The hardware server URL must be
provided via the `HW_SERVER_URL` variable.

`boot-jtag-psinit-uboot`
: Boot board into U-Boot via JTAG, but run `ps*_init.tcl` script instead of
downloading and running FSBL. This can be inconvenient if the FSBL is doing
boot mode specific jobs, e.g. loading a boot image from QSPI flash memory when
in QSPI boot mode, although one does NOT want the FSBL to do that.  The
hardware server URL must be provided via the `HW_SERVER_URL` variable. Only
available on Zynq-7000 as of now.

`boot-qemu`
: Boot into QEMU.

`flash-boot`
: Flash boot image onto board via JTAG. The hardware server URL must be
provided via the `HW_SERVER_URL` variable. The flash type must be specified
with the `FLASH_TYPE` variable if it deviates from the default. The FSBL used
for flashing, the boot image and the flash offset can be changed with the
`FSBL_ELF`, `BOOT_BIN` and `BOOT_BIN_OFF` variables respectively.

`flash-kernel`
: Flash kernel image onto board via JTAG. The hardware server URL must be
provided via the `HW_SERVER_URL` variable. The flash type must be specified
with the `FLASH_TYPE` variable if it deviates from the default. The FSBL used
for flashing, the kernel image and the flash offset can be changed with the
`FSBL_ELF`, `KERNEL_IMG` and `KERNEL_IMG_OFF` variables respectively.

`flash`
: Flash boot and kernel image onto board via JTAG.

`mrproper`
: Clean all build artifacts. If this target is invoked with `CLEAN_HDF=1`, the
HDF is deleted as well (i.e. all files in folder `project-spec/hw-description`
except file `metadata`).


### Extending

If you need additional functionality in your project, put it into a file named
`local.mk`.


## XSDK Makefile

The XSDK Makefile provides a declarative wrapper around the Xilinx Software
Command-Line Tool (XSCT) and Bootgen to streamline the build of Xilinx Software
Development Kit (XSDK) projects.


### Supported Platforms

XSDK is supported from v2018.1 to v2019.1 (i.e. the last four releases). The
Makefile should run on all underlying Linux OSs supported by XSDK, but not
Windows. However, testing is only conducted on Ubuntu 18.04 LTS (Bionic Beaver)
as of now.


### Build Configuration Syntax

The XSDK Makefile is configured via a custom syntax as documented in the
following sections.


#### Hardware Platform Specification

The Hardware Platform Specification captures all the information from a
hardware design that is required to write, debug and deploy software
applications for that hardware. In the XSDK Makefile, there is exactly one
hardware platform specification called `hw` by default [^1]. The hardware
platform specification is derived from the Hardware Description File (HDF)
imported during build (see section Usage) and does not need to be configured.

[^1]: The hardware platform specification name can be changed with the `HW_PRJ`
      variable if necessary.

#### Repositories

A software repository is a directory that holds third-party software
components, as well as custom drivers, libraries, and operating systems. You
can register repositories in the workspace by adding the respective path to the
`REPOS` variable.

#### Board Support Packages

A Board Support Package (BSP) is a collection of libraries and drivers that
form the basis of software applications (see section "Applications").

BSPs are registered by adding their name to the `BSP_PRJS` list. They can then
be configured by prefixing the corresponding option with their name:

    BSP_PRJS += fsbl_bsp
    fsbl_bsp_PROC = psu_cortexa53_0
    fsbl_bsp_IS_FSBL = yes
    fsbl_bsp_LIBS = xilffs xilsecure xilpm
    fsbl_bsp_POST_CREATE_TCL = configbsp -bsp fsbl_bsp use_strfunc 1

    BSP_PRJS += gen_bsp
    gen_bsp_PROC = psu_cortexa53_0
    gen_bsp_STDOUT = psu_uart_1

The following BSP options are available:

`OS`
: Operating system type. Optional, defaults to `standalone`. Run `repo -os` in
XSCT to get a list of all OSs.

`PROC`
: Processor instance. Run `toolchain` in XSCT to get a list of supported
processor types.

`ARCH`
: Processor architecture. Can be 32 or 64 bit. Valid only for processors
supporting multiple architectures (e.g. A53).

`PATCH`
: List of space-separated patch file entries. Patches are applied in the base
directory of the respective BSP project. A patch file list entry has the format
`<patchfile>[;stripnum]`, where `stripnum` is the optional number of leading
slashes to be stripped from each file name found in the patch file (default is
1).

`SED`
: List of space-separated file entries to be transformed with sed (stream
editor). Sed is run in the base directory of the respective BSP project. A sed
list entry has the format `<srcfile>;<sedfile>`, where `<srcfile>` is the file
to be transformed and `<sedfile>` the sed script file.

`IS_FSBL`
: If `yes`, apply non-default BSP settings for FSBL.

`EXTRA_CFLAGS`
: Additional compiler flags (default `-g -Wall -Wextra`). The default
optimization level of `-O2` can be overriden with this variable.

`STDIN`
: Select UART for standard input.

`STDOUT`
: Select UART for standard output.

`LIBS`
: List of libraries to be added to the BSP. Run `repo -lib` in XSCT to get a
list of available libraries.

`POST_CREATE_TCL`
: Hook for adding extra Tcl commands after the BSP has been created. Can be
used to configure BSP settings (via the `configbsp` command) not available in
the XSDK Makefile.


#### Applications

Software application projects are your final application containers. They can
either be derived from a template or contain your own source files. Each
application project must be linked to exactly one BSP.

Application projects are registered by adding their name to the `APP_PRJS`
list. They can then be configured by prefixing the corresponding option with
their name:

    APP_PRJS += fsbl
    fsbl_TMPL = Zynq MP FSBL
    fsbl_BSP = fsbl_bsp
    fsbl_CPPSYMS = FSBL_DEBUG_DETAILED

    APP_PRJS += helloworld
    helloworld_TMPL = Hello World
    helloworld_BSP = gen_bsp
    helloworld_BCFG = Debug
    helloworld_PATCH = helloworld.patch
    helloworld_SED = platform.c;baud_rate.sed

The following application project options are available:

`TMPL`
: Name of the template to base the application project on. Run `repo -apps` in
XSCT to get a list of available application templates.

`PROC`
: Processor instance. Run `toolchain` in XSCT to get a list of supported
processor types.

`BSP`
: Reference to BSP. Required.

`SRC`
: List of space-separated source files to be added to the application. For each
list entry, a symlink in the `src` directory of the respective application
project will be created that points towards the corresponding source file.

`PATCH`
: List of space-separated patch file entries. Patches are applied in the `src`
directory of the respective application project. A patch file list entry has
the format `<patchfile>[;stripnum]`, where `stripnum` is the optional number of
leading slashes to be stripped from each file name found in the patch file
(default is 1).

`SED`
: List of space-separated file entries to be transformed with sed (stream
editor). Sed is run in the `src` directory of the respective application
project. A sed list entry has the format `<srcfile>;<sedfile>`, where
`<srcfile>` is the file to be transformed and `<sedfile>` the sed script file.

`BCFG`
: Build configuration. Can either be `Release` (default) or `Debug`.

`OPT`
: Compiler optimization level. Can either be `None (-O0)`, `Optimize (-O1)`,
`Optimize more (-O2)` (default), `Optimize most (-O3)`, `Optimize for size
(-Os)`.

`CPPSYMS`
: List of preprocessor symbols (e.g. `MYSYMBOL=1`).

`POST_CREATE_TCL`
: Hook for adding extra Tcl commands after the application project has been
created. Can be used to set application project configuration parameters (via
the `configapp` command) not available in the XSDK Makefile.


#### Bootgen

Bootgen is a Xilinx tool that merges build artifacts into a boot image
according to a Boot Image Format (BIF) file. The XSDK Makefile can generate BIF
files and invoke Bootgen subsequently.

Bootgen projects are registered by adding their name to the `BOOTGEN_PRJS`
list. They can then be configured by prefixing the corresponding option with
their name:

    BOOTGEN_PRJS += bootbin
    bootbin_BIF_ARCH = zynqmp

The following Bootgen project options are available:

`BIF_ARCH`
: Device architecture. Run `bootgen` and see description of `-arch` option for
a list of supported architectures.

`BIF_ARGS_EXTRA`
: Add additional Bootgen arguments for special operations like key generation.

`NO_OUTPUT`
: If `yes`', do not write a boot image file. Required for certain operations
like key generation.

`FLASH_TYPE`
: Flash memory type. Run `program_flash` and see description of option
`-flash_type` to get a list of supported memory types. Only needed for `flash`
target (see section "Usage").

`FLASH_FSBL`
: FSBL used for flashing. Only needed for `flash` target (see section "Usage").

`FLASH_OFF`
: Offset within the flash memory at which the image should be written. Only
needed for `flash` target (see section "Usage").

BIF attributes are then registered by adding their name to the `BIF_ATTRS`
list. They can then be configured by prefixing the `BIF_ATTR` and `BIF_FILE`
variables with the Bootgen project name and BIF attribute name:

    bootbin_BIF_ATTRS = fsbl helloworld
    bootbin_fsbl_BIF_ATTR = bootloader, destination_cpu=a53-0
    bootbin_fsbl_BIF_FILE = fsbl/$(fsbl_BCFG)/fsbl.elf
    bootbin_helloworld_BIF_ATTR = destination_cpu=a53-0
    bootbin_helloworld_BIF_FILE = helloworld/$(helloworld_BCFG)/helloworld.elf

This example is translated to the following BIF file:

    bootbin:
    {
        [bootloader, destination_cpu=a53-0] fsbl/Release/fsbl.elf
        [destination_cpu=a53-0] helloworld/Debug/helloworld.elf
    }

The file name of a bitstream depends on the Vivado design and is often not
known before the HDF has been extracted. In these cases, by convention, one
should point the corresponding `BIF_FILE` option to a variable named like
`BIT`:

    bootbin_bit_BIF_ATTR = destination_device=pl
    bootbin_bit_BIF_FILE = $(BIT)

The `BIT` variable must then be provided on invocation:

    $ make HDF=<path-to-your-hdf> BIT=hw/<bitstream>.bit

Optionally, one can provide a default as well:

    BIT ?= hw/design_1_wrapper.bit


### Setup

Create a symlink named `Makefile` to the `xsdk.mk` file:

    $ ln -s ../scripts/xsdk.mk Makefile

Add the `build` directory to your `.gitignore`.

By default, the XSDK Makefile looks for the build configuration in
`./default.mk`. If you choose a different file name (or like to have multiple
build configurations), you can specify the path with the `CFG` variable.

Write your build configuration as documented in section "Makefile syntax".
Instead of writing the build configuration from scratch, you can also copy
`templates/default.mk` into your working directory.


### Usage

Import a HDF and build all projects by executing:

    $ make HDF=<path-to-your-hdf>

The XSDK Makefile creates a new XSDK workspace as a subfolder in directory
`build` named `<cfg-file-name>_<date>-<time>_<git-commit-id>`. A new XSDK
workspace is created on each invocation. If you would like to run the XSDK
Makefile on a specific workspace instead of creating a new one, you can use the
`O` variable:

    $ make O=build/<cfg-file-name>_<date>-<time>_<git-commit-id>

The XSDK Makefile dynamically creates targets according to the build
configuration. Each BSP, application project and Bootgen project is assigned a
build target with the same name. Additionally each BSP and application project
feature a `clean` and `distclean` target separated by `_`.  In order to e.g.
clean the application project `helloworld`, one would execute:

    $ make helloworld_clean

Bootgen projects come with a `flash` target to write the boot image onto a
board via JTAG. In order to e.g. flash the Bootgen project `bootbin`, one would
execute:

    $ make bootbin_flash HW_SERVER_URL=<hw-server-url>

In addition, the following generic Makefile targets are available:

`hw`
: Build the hardware platform specification. You must provide a HDF via the
`HDF` variable.

`hw_distclean`
: Clean the hardware platform specification.

`generate`
: Generate all projects.

`build` (default)
: Build all projects.

`metalog`
: Show meta log.

`sdklog`
: Show XSDK log.

`xsdk`
: Run XSDK.

`clean`
: Clean all projects.

`distclean`
: Remove workspace.


### Extending

The build configuration file can be extended with standard Makefile targets for
e.g. uploading and running build artifacts via JTAG.


## License

Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).