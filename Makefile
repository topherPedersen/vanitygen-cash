LIBS=-lpcre -lcrypto -lm -lpthread -lhs
CFLAGS=-Wall -Wextra #-Wno-unused-variable
OBJS=vanitygen.o oclvanitygen.o oclvanityminer.o oclengine.o keyconv.o pattern.o util.o cashaddr.o
PROGS=vanitygen keyconv oclvanitygen oclvanityminer
# OPTIMIZE
# -O0 = no optimization
# -O3 = good optimization
# -Ofast = aggressive optimization
# -Os = small file size
# -Og -g -ggdb debugging
CFLAGS+=-O0 -g -ggdb

PLATFORM=$(shell uname -s)
ifeq ($(PLATFORM),Darwin)
	ifneq ($(wildcard /usr/local/opt/gcc/bin/*),)
		CC=/usr/local/opt/gcc/bin/g++-7
	else
		# support for Xcode/clang
		CC=g++
		CFLAGS+=-std=c++14
	endif
	ifneq ($(wildcard /usr/local/opt/openssl@1.1/lib/*),)
		LIBS+=-L/usr/local/opt/openssl@1.1/lib
		CFLAGS+=-I/usr/local/opt/openssl@1.1/include
	else
		LIBS+=-L/usr/local/opt/openssl/lib
		CFLAGS+=-I/usr/local/opt/openssl/include
	endif
	OPENCL_LIBS=-framework OpenCL
	LIBS+=-L/usr/local/opt/hyperscan/lib
	CFLAGS+=-I/usr/local/opt/hyperscan/include
	# Below 2 lines add support for MacPorts
	LIBS+=-L/opt/local/lib
	CFLAGS+=-I/opt/local/include
else ifeq ($(PLATFORM),NetBSD)
	LIBS+=`pcre-config --libs`
	CFLAGS+=`pcre-config --cflags`
else
	CC=g++-7
	OPENCL_LIBS=-lOpenCL
endif

most: vanitygen

all: vanitygen oclvanitygen

vanitygen: vanitygen.o pattern.o util.o cashaddr.o
	$(CC) $^ -o $@-cash $(CFLAGS) $(LIBS)

oclvanitygen: oclvanitygen.o oclengine.o pattern.o util.o cashaddr.o
	$(CC) $^ -o $@-cash $(CFLAGS) $(LIBS) $(OPENCL_LIBS)

oclvanityminer: oclvanityminer.o oclengine.o pattern.o util.o cashaddr.o
	$(CC) $^ -o $@ $(CFLAGS) $(LIBS) $(OPENCL_LIBS) -lcurl

keyconv: keyconv.o util.o cashaddr.o
	$(CC) $^ -o $@ $(CFLAGS) $(LIBS)

clean:
# DON'T RUN IF YOU DO `make -f` or `--file`
	rm -rf vanitygen-cash.dSYM keyconv.dSYM oclvanitygen-cash.dSYM oclvanityminer.dSYM *.o *vanitygen-cash keyconv *.oclbin *miner *plist

format:
	clang-format -i -verbose -style=file cashaddr.c cashaddr.h keyconv.c oclengine.c pattern.c pattern.h util.c vanitygen.c avl.h oclengine.h oclvanitygen.c oclvanityminer.c util.h winglue.c winglue.h
