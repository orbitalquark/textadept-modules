# Copyright 2015-2020 Mitchell. See LICENSE.

ta_src = /home/mitchell/code/textadept/src

CXX = g++
CXXFLAGS = -std=c++0x -pedantic -fPIC -Wall
LDFLAGS = -Wl,--retain-symbols-file -Wl,$(ta_src)/lua.sym

all: spell.so spell.dll spell-curses.dll spellosx.so
clean: ; rm -f *.o *.so *.dll

# Platform objects.

CROSS_WIN = i686-w64-mingw32-
CROSS_OSX = x86_64-apple-darwin17-
CXXFLAGS_OSX = -undefined dynamic_lookup -fPIC -Wall

hunspell_objs = affentry.o affixmgr.o csutil.o filemgr.o hashmgr.o \
                hunspell.o hunzip.o phonet.o replist.o suggestmgr.o
hunspell_win_objs = $(addsuffix -win.o, $(basename $(hunspell_objs)))
hunspell_osx_objs = $(addsuffix -osx.o, $(basename $(hunspell_objs)))

spell.so: lspell.o $(hunspell_objs)
	$(CXX) -shared $(CXXFLAGS) -o $@ $^ $(LDFLAGS)
spell.dll: lspell-win.o $(hunspell_win_objs) lua.la
	$(CROSS_WIN)$(CXX) -shared -static-libgcc -static-libstdc++ $(CXXFLAGS) -o \
		$@ $^ $(LDFLAGS)
spell-curses.dll: lspell-win.o $(hunspell_win_objs) lua-curses.la
	$(CROSS_WIN)$(CXX) -shared -static-libgcc -static-libstdc++ $(CXXFLAGS) -o \
		$@ $^ $(LDFLAGS)
spellosx.so: lspell-osx.o $(hunspell_osx_objs)
	$(CROSS_OSX)$(CXX) -shared $(CXXFLAGS_OSX) -o $@ $^

lspell.o: lspell.cxx
	$(CXX) -c $(CXXFLAGS) -I$(ta_src)/lua/src -Ihunspell -o $@ $^
lspell-win.o: lspell.cxx
	$(CROSS_WIN)$(CXX) -c $(CXXFLAGS) -DLUA_BUILD_AS_DLL -DLUA_LIB \
		-I$(ta_src)/lua/src -Ihunspell -o $@ $^
lspell-osx.o: lspell.cxx
	$(CROSS_OSX)$(CXX) -c $(CXXFLAGS_OSX) -I$(ta_src)/lua/src -Ihunspell -o $@ $^

$(hunspell_objs): %.o: hunspell/hunspell/%.cxx
	$(CXX) -c $(CXXFLAGS) -Ihunspell $< -o $@
$(hunspell_win_objs): %-win.o: hunspell/hunspell/%.cxx
	$(CROSS_WIN)$(CXX) -c $(CXXFLAGS) -Ihunspell $< -o $@
$(hunspell_osx_objs): %-osx.o: hunspell/hunspell/%.cxx
	$(CROSS_OSX)$(CXX) -c $(CXXFLAGS_OSX) -Ihunspell $< -o $@

lua.def:
	echo LIBRARY \"textadept.exe\" > $@ && echo EXPORTS >> $@
	grep -v "^#" $(ta_src)/lua.sym >> $@
lua.la: lua.def
	$(CROSS_WIN)dlltool -d $< -l $@
lua-curses.def:
	echo LIBRARY \"textadept-curses.exe\" > $@ && echo EXPORTS >> $@
	grep -v "^#" $(ta_src)/lua.sym >> $@
lua-curses.la: lua-curses.def
	$(CROSS_WIN)dlltool -d $< -l $@

# External Hunspell dependency.

deps: hunspell

hunspell_tgz = hunspell-1.3.3.tar.gz
$(hunspell_tgz): ; wget http://downloads.sourceforge.net/hunspell/$@
hunspell: | $(hunspell_tgz)
	mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
	mv $@/src/hunspell $@
	touch $@/hunspell/config.h
