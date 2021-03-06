# Copyright 2017-2020 Mitchell. See LICENSE.

ta_src = /home/mitchell/code/textadept/src

CXX = g++
CXXFLAGS = -g -std=c++0x -pedantic -fPIC -Wall
LDFLAGS = -Wl,--retain-symbols-file -Wl,$(ta_src)/lua.sym

all: diff.so diff.dll diff-curses.dll diffosx.so
clean: ; rm -f *.o *.so *.dll

CROSS_WIN = i686-w64-mingw32-
CROSS_OSX = x86_64-apple-darwin17-
CXXFLAGS_OSX = -undefined dynamic_lookup -fPIC -Wall

diff.so: ldiff.o
	$(CXX) -shared $(CXXFLAGS) -o $@ $^ $(LDFLAGS)
diff.dll: ldiff-win.o lua.la
	$(CROSS_WIN)$(CXX) -shared -static-libgcc -static-libstdc++ $(CXXFLAGS) -o \
		$@ $^ $(LDFLAGS)
diff-curses.dll: ldiff-win.o lua-curses.la
	$(CROSS_WIN)$(CXX) -shared -static-libgcc -static-libstdc++ $(CXXFLAGS) -o \
		$@ $^ $(LDFLAGS)
diffosx.so: ldiff-osx.o
	$(CROSS_OSX)$(CXX) -shared $(CXXFLAGS_OSX) -o $@ $^

ldiff.o: ldiff.cxx
	$(CXX) -c $(CXXFLAGS) -I$(ta_src)/lua/src -o $@ $^
ldiff-win.o: ldiff.cxx
	$(CROSS_WIN)$(CXX) -c $(CXXFLAGS) -DLUA_BUILD_AS_DLL -DLUA_LIB \
		-I$(ta_src)/lua/src -o $@ $^
ldiff-osx.o: ldiff.cxx
	$(CROSS_OSX)$(CXX) -c $(CXXFLAGS_OSX) -I$(ta_src)/lua/src -o $@ $^

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

# External diff_match_patch dependency.

deps: diff_match_patch.h

diff_match_patch_zip = 7f95b37e554453262e2bcda830724fc362614103.zip
$(diff_match_patch_zip):
	wget https://github.com/leutloff/diff-match-patch-cpp-stl/archive/$@
diff_match_patch.h: | $(diff_match_patch_zip) ; unzip -j $| "*/$@"
