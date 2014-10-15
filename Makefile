# Makefile for Lab03-Blinky, ELEC424 Fall 2014
# Authors: Jie Liao, Abeer Javed, Steven Arroyo. Rice University 
# Derived from the crazyflie-firmware Makefile

# Filename defination
FILENAME = $(notdir $(CURDIR))

# Path Definitions
PRO_ROOT = .
STM_ROOT = STM32F10x_StdPeriph_Lib_V3.5.0
STM_LIB =  $(STM_ROOT)/Libraries
STARTUP_PATH = $(STM_LIB)/CMSIS/CM3/DeviceSupport/ST/STM32F10x/startup/TrueSTUDIO
DEV_LIB = $(STM_LIB)/STM32F10x_StdPeriph_Driver
SYS_LIB = $(STM_LIB)/CMSIS/CM3/DeviceSupport/ST/STM32F10x
CORE_LIB = $(STM_LIB)/CMSIS/CM3/CoreSupport

#VPATH for searching files
VPATH += $(STARTUP_PATH)  $(DEV_LIB)/src $(SYS_LIB)

# Compiler 
CC = arm-none-eabi-gcc

# Particular processor
PROCESSOR = -mcpu=cortex-m3 -mthumb

# Directories of used header files
INCLUDE = -I. -I$(DEV_LIB)/inc -I$(SYS_LIB) -I$(CORE_LIB)

# STM chip specific flags
STFLAGS = -DSTM32F10X_MD -include $(PRO_ROOT)/stm32f10x_conf.h

#Application specific flags
APPFLAGS = -DPROCISE_DELAY

# Define the compiler flags
CFLAGS = -O0 -g3 $(PROCESSOR) $(INCLUDE) $(STFLAGS) -Wl,--gc-sections -T $(PRO_ROOT)/stm32_flash.ld

# object files
OBJS = $(STARTUP_PATH)/startup_stm32f10x_md.s \
	main.c \
	stm32f10x_it.c\
	$(DEV_LIB)/src/stm32f10x_rcc.c \
	$(DEV_LIB)/src/stm32f10x_tim.c \
	$(DEV_LIB)/src/stm32f10x_gpio.c \
	$(SYS_LIB)/system_stm32f10x.c
	
# Build all relevant files and create .elf
all: compile flash

compile:
	@$(CC) $(CFLAGS) $(OBJS) -o $(FILENAME).elf

# Program .elf into Crazyflie flash memory via the busblaster
OCDFLAG =  -d0 -f interface/busblaster.cfg -f target/stm32f1x.cfg -c init -c targets -c "reset halt" 
flash:
	@openocd $(OCDFLAG) -c "flash write_image erase $(FILENAME).elf" -c "verify_image $(FILENAME).elf" -c "reset run" -c shutdown

# Runs OpenOCD, opens GDB terminal, and establishes connection with Crazyflie
debug:
	openocd $(OCDFLAG) &
	arm-none-eabi-gdb -tui $(FILENAME).elf --eval-command="target remote:3333" 
	ps axf | grep openocd |grep -v grep | awk '{print "kill " $$1}' | sh

#Kill openocd when for some reason openocd haven't closed automatically
kill:
	ps axf | grep openocd |grep -v grep | awk '{print "kill " $$1}' | sh
#stop the running program in the mechine
stop:
	@openocd $(OCDFLAG) -c shutdown
# Remove all files generated by target 'all'
clean:
	rm -f *~ *.elf
