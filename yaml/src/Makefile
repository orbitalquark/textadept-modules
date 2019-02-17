# Copyright 2014-2019 Mitchell mitchell.att.foicica.com. See LICENSE.

ifeq (win32, $(findstring win32, $(MAKECMDGOALS)))
  CROSS = i686-w64-mingw32-
  CC = gcc
  CFLAGS += -DYAML_DECLARE_STATIC
  LUA_CFLAGS = -DLUA_BUILD_AS_DLL -DLUA_LIB
  LDFLAGS = lua.la -Wl,--retain-symbols-file -Wl,lua.sym
  target = ../libyaml.dll
else ifeq (osx, $(findstring osx, $(MAKECMDGOALS)))
  CROSS = x86_64-apple-darwin9-
  CC = gcc
  CFLAGS = -undefined dynamic_lookup
  target = ../libyamlosx.so
else
  CC = gcc
  CFLAGS = -fPIC
  LDFLAGS = -Wl,--retain-symbols-file -Wl,lua.sym
  target = ../libyaml.so
endif

yaml_objs = api.o dumper.o emitter.o loader.o parser.o reader.o scanner.o \
            writer.o
lua_objs = lemitter.o lparser.o lscanner.o lyaml.o

all: $(target)
win32: lua.la $(target)
osx: $(target)

ta_src = $(HOME)/code/textadept/src

$(yaml_objs): %.o: %.c
	$(CROSS)$(CC) -c $(CFLAGS) -DHAVE_CONFIG_H -I. $< -o $@
$(lua_objs): %.o: %.c
	$(CROSS)$(CC) -c $(CFLAGS) $(LUA_CFLAGS) -I. -I$(ta_src)/lua/src $< -o \
		$@
$(target): $(yaml_objs) $(lua_objs)
	$(CROSS)$(CC) $(CFLAGS) -shared -o $@ $^ $(LDFLAGS)
lua.def:
	echo LIBRARY \"textadept.exe\" > $@ && echo EXPORTS >> $@
	grep -v "^#" $(ta_src)/lua.sym >> $@
lua.la: lua.def
	$(CROSS)dlltool -d $< -l $@
clean:
	rm -f *.o
