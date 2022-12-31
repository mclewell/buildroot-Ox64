# Buildroot for the Pine64 Ox64

Minimal Linux distribution based on Buildroot for the Pine64 Ox64 RISC-V board.

## Connections
Power: Provide via Micro USB on J3

Flashing: UART0 on Pins 1 and 2

Serial Console: UART3 on Pins 31 and 32

![](/doc/Ox64pinout.png "Pine64 Ox64 Pinout"){width=75%}

## Setup
This repo leverages the BSP source from the [Bouffalo Labs Repo](https://github.com/bouffalolab/bl808_linux). The source for the Kernel, OpenSBI,
etc. are provided in this single repo. Typically, these would be provided and
managed as separate repos -- which is indeed what Buildroot expects. To work
around this issue, git submodules are used to pull down all the source. A
[Buildroot local override file](board/pine64/ox64/local.mk) is then used to 
specify the local source to build against.

### Setting up the Buildroot Environment
Tested on Ubuntu 20.04. Install the Buildroot dependencies:
```
sudo apt install sed make binutils gcc g++ bash patch \
    gzip bzip2 perl tar cpio python unzip rsync wget libncurses-dev
```
Clone this repo and initialize the submodules:
```
git clone https://github.com/mclewell/buildroot-Ox64
git submodule update --init
```

### Applying Patches
There are three patches that need to be applied. 
1. Change the console output to UART3 so that we can see and interact with Linux
(pins 31/32)
2. Disable stack pointer protection when building OpenSBI
3. Increase the SPI flash partition size so our image will fit.

These patches are in the [patches](/patches/) directory. The 
```apply-patches.sh``` script will automatically apply these for you.

## Build
The BL808 contains three CPUs:
1. M0: RISC-V RV32IMAFCP - Used as a co-processor to setup the PMU
2. D0: RISC-V RV64IMAFCV - Main application processor where Linux will run
3. LP: RISC-V RV32EMC - Low-power CPU, not used here.

The BL808 BootROM first loads a small program on each CPU. The M0 application 
appears to just setup some peripherals and the PMU and then spins in a loop 
forever. The D0 application does some initial setup for this CPU and then jumps
to OpenSBI which then loads Linux directly (no U-Boot).

The M0/D0 applications need to be built and loaded with Bouffalo Lab's flashing
tool called DevCube. These applications require a different toolchain than what
is used to build Linux and the rootfs. Buildroot does not support building with 
multiple toolchains. Therefore, these will need to be built separately. See the
[Bouffalo Labs Repo](https://github.com/bouffalolab/bl808_linux). If you want to
skip this step, I have provided pre-built boot-images in this repo. They will be 
automatically copied to the output ```images``` directory after building the 
main image.

### Optional: Build the M0/D0 Boot Images
Building these yourself is not difficult. Since we already have the source from 
our git submodule, we can go ahead and build these in-place:
```
cd board/pine64/ox64/bl808_linux
mkdir -p toolchain/cmake toolchain/elf_newlib_toolchain
curl https://cmake.org/files/v3.19/cmake-3.19.3-Linux-x86_64.tar.gz | tar xz -C toolchain/cmake/ --strip-components=1
curl https://occ-oss-prod.oss-cn-hangzhou.aliyuncs.com/resource//1663142243961/Xuantie-900-gcc-elf-newlib-x86_64-V2.6.1-20220906.tar.gz | tar xz -C toolchain/elf_newlib_toolchain/ --strip-components=1
./build.sh low_load
```
The resulting binaries will be in the ```out``` directory. We will use these
later in DevCube when we flash the SPI Flash on the Ox64.

### Building OpenSBI, Linux, and a RootFS
We will be doing an out-of-tree Buildroot build. As such, we need to create an
output directory:
```
cd buildroot-ox64/buildroot
mkdir output-ox64
cd output-ox64
```
Setup the build:
```
make -C ../ O=$(pwd) BR2_EXTERNAL=$PWD/../../ pine64_ox64_defconfig
```
Start the build:
```
make
```
Once complete, the resulting flash image will be at: ```images/whole_img_linux.bin```

## Flashing
Flashing the Ox64 is done via UART0 on pins 1 and 2. There have been reports of
issues with some USB-UART adapters. See the [Ox64 Wiki](https://wiki.pine64.org/wiki/Ox64#Compatible_UARTs_when_in_bootloader_mode) 
for discussion and some suggested workarounds.

Bouffalo Labs Dev Cube software is used to flash the board. It can be [downloaded from here](https://dev.bouffalolab.com/download).

1. Download and extract Dev Cube
2. Run ./BLDevCube-ubuntu (you might need to ```chmod +x``` it)
3. Select BL808 as the chip
4. Change to the "MCU" tab on the top. Select the D0/M0 image that you build 
earlier (or the pre-built ones in the ```images``` directory). Set the following ([example screenshot](/doc/dev_cube_mcu.png)):
    - MO: 
        - Group: group0
        - Image Addr: 0x58000000
        - Select low_load_bl808_m0.bin
    - DO: 
        - Group: group1
        - Image Addr: 0x58000000
        - Select low_load_bl808_d0.bin
    - LP: Leave everything blank.
5. On the right most panel, ensure the correct serial port is selected. You can 
also decrease the baud rate from 2000000 if you have issues flashing.
6. Put the Ox64 into bootloader mode by holding down the "BOOT" button while
connecting power through the Micro-USB port. Release the button once the green 
LED lights.
7. Click "Create & Download" on the right. 
    - If you see handshake or read errors, check your UART connections or try 
    reducing the baud rate.
8. Switch to the "IOT" tab on the top. 
9. Tick the "Enable" box under "Single Image Download". Set the following:
10. In the first, shorter box, enter ```0xD2000``` as the load address and
select the output image that Buildroot built from ```images/whole_img_linux.bin``` ([example screenshot](/doc/dev_cube_iot.png)):
    - DevCube will first erase the region to be flashed and them load the image.
    The process will take a few minutes.
11. Once complete, cycle power on the Ox64. UART3 (pins 31/32) will display the
console output.
