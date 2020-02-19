# Copyright 2017-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

ta_src = /home/mitchell/code/textadept/src

CXX = g++
CXXFLAGS = -g -std=c++0x -pedantic -fPIC -Wall
LDFLAGS = -Wl,--retain-symbols-file -Wl,$(ta_src)/lua.sym

all: diff64.so diff.dll diffosx.so diff.so
clean:
	rm -f *.o *.so *.dll

zip: README LICENSE init.lua diff64.so diff.dll diffosx.so diff.so diff.luadoc
	mkdir file_diff && cp $^ file_diff
	zip -r file_diff.zip file_diff
	rm -r file_diff

CROSS_WIN = i686-w64-mingw32-
CROSS_OSX = x86_64-apple-darwin9-
CXXFLAGS_OSX = -undefined dynamic_lookup -fPIC -Wall

diff64.so: ldiff64.o
	$(CXX) -shared $(CXXFLAGS) -o $@ $^ $(LDFLAGS)
diff.dll: ldiff-win.o lua.la
	$(CROSS_WIN)$(CXX) -shared -static-libgcc -static-libstdc++ $(CXXFLAGS) -o \
		$@ $^ $(LDFLAGS)
diffosx.so: ldiff-osx.o
	$(CROSS_OSX)$(CXX) -shared $(CXXFLAGS_OSX) -o $@ $^
diff.so: ldiff-i386.o
	$(CXX) -m32 -shared $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

ldiff64.o: ldiff.cxx
	$(CXX) -c $(CXXFLAGS) -I$(ta_src)/lua/src -o $@ $^
ldiff-win.o: ldiff.cxx
	$(CROSS_WIN)$(CXX) -c $(CXXFLAGS) -DLUA_BUILD_AS_DLL -DLUA_LIB \
		-I$(ta_src)/lua/src -o $@ $^
ldiff-osx.o: ldiff.cxx
	$(CROSS_OSX)$(CXX) -c $(CXXFLAGS_OSX) -I$(ta_src)/lua/src -o $@ $^
ldiff-i386.o: ldiff.cxx
	$(CXX) -m32 -c $(CXXFLAGS) -I$(ta_src)/lua/src -o $@ $^

lua.def:
	echo LIBRARY \"textadept.exe\" > $@ && echo EXPORTS >> $@
	grep -v "^#" $(ta_src)/lua.sym >> $@
lua.la: lua.def
	$(CROSS_WIN)dlltool -d $< -l $@

# External diff_match_patch dependency.

deps: diff_match_patch.h

diff_match_patch_zip = 7f95b37e554453262e2bcda830724fc362614103.zip
$(diff_match_patch_zip):
	wget https://github.com/leutloff/diff-match-patch-cpp-stl/archive/$@
diff_match_patch.h: | $(diff_match_patch_zip) ; unzip -j $| "*/$@"
