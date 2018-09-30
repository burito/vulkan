
UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
# MacOS
BUILD_DIR = $(MAC_DIR)
GLSLANG = deps/mac/glslangValidator
CC = clang -g
default: vulkan.bin

else
ifeq ($(UNAME), Linux)
# Linux
BUILD_DIR = $(LIN_DIR)
GLSLANG = deps/lin/glslangValidator
CC = clang -g
default: vulkan

else
# Windows
BUILD_DIR = $(WIN_DIR)
GLSLANG = deps/win/glslangValidator.exe
CC = gcc -g
default: vulkan.exe
endif
endif

OBJS = log.o vulkan.o vulkan_helper.o
CFLAGS = -Ideps/include
VPATH = src

WIN_LIBS = c:/Windows/system32/vulkan-1.dll -luser32 -lwinmm -lgdi32
LIN_LIBS = -Ldeps/lin -lvulkan -lxcb
MAC_LIBS = -Ldeps/mac -lMoltenVK -framework CoreVideo -framework QuartzCore -rpath . -framework Cocoa
# replace -lxcb with -lX11 if using Xlib

WIN_DIR = build/win
LIN_DIR = build/lin
MAC_DIR = build/mac

_WIN_OBJS = win32.o $(OBJS)
_LIN_OBJS = linux_xcb.o $(OBJS)
_MAC_OBJS = macos.o $(OBJS)

WIN_OBJS = $(patsubst %,$(WIN_DIR)/%,$(_WIN_OBJS))
LIN_OBJS = $(patsubst %,$(LIN_DIR)/%,$(_LIN_OBJS))
MAC_OBJS = $(patsubst %,$(MAC_DIR)/%,$(_MAC_OBJS))


CFLAGS += -Ibuild

$(WIN_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(LIN_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(MAC_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(MAC_DIR)/macos.o: macos.m
	$(CC) $(CFLAGS) -c $< -o $@

libMoltenVK.dylib: deps/mac/libMoltenVK.dylib
	cp deps/mac/libMoltenVK.dylib .

vulkan.exe: $(WIN_OBJS)
	$(CC) $^ $(WIN_LIBS) -o $@

vulkan: $(LIN_OBJS)
	$(CC) $(CFLAGS) $(LIN_LIBS) $^ -o $@

vulkan.bin: $(MAC_OBJS) libMoltenVK.dylib
	$(CC) $(CFLAGS) $(MAC_LIBS) $^ -o $@


$(BUILD_DIR)/vulkan.o: vulkan.c build/vert_spv.h build/frag_spv.h

vulkan.app: vulkan.bin
	rm -rf $@
	mkdir -p $@/Contents
	cp Info.plist $@/Contents
	mkdir $@/Contents/MacOS
	cp $< $@/Contents/MacOS/vulkan	

build/frag.spv : shader.frag
	$(GLSLANG) -V -H $< -o $@ > build/frag_spv.h.txt

build/vert.spv : shader.vert
	$(GLSLANG) -V -H $< -o $@ > build/vert_spv.h.txt

build/vert_spv.h : build/vert.spv
	xxd -i $< > $@ 

build/frag_spv.h : build/frag.spv
	xxd -i $< > $@

clean:
	@rm -rf build vulkan vulkan.exe vulkan.bin vulkan.app libMoltenVK.dylib 

$(shell	mkdir -p $(BUILD_DIR))