# cut is necessary for Cygwin
PLATFORM_OS := $(shell uname | cut -d_ -f1)
CC = clang

all: bin2png png2bin

clean:
	@rm -rf *.o bin2png png2bin

CFLAGS += -D_XOPEN_SOURCE=600 -std=c99 -Wall -Wextra
LDFLAGS += -lpng

ifeq ($(PLATFORM_OS), Linux)
	LDFLAGS += -lm # required for sqrt()
endif

common.o: common.h
	echo $(PLATFORM_OS)
	$(CC) -o $@ -c common.c $(CFLAGS)

imgify.o: imgify.h
	$(CC) -o $@ -c imgify.c $(CFLAGS)

bin2png: common.o imgify.o
	$(CC) -o $@ bin2png.c $^ $(CFLAGS) $(LDFLAGS)

png2bin: common.o imgify.o
	$(CC) -o $@ png2bin.c $^ $(CFLAGS) $(LDFLAGS)
	
.PHONY: debug release sanitize sanitize-demo coverage fuzz

debug: CFLAGS += -O0 -g3
debug: clean all

release: CFLAGS += -O2 -DNDEBUG
release: clean all

sanitize: CFLAGS += -O0 -g3 -fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=all
sanitize: LDFLAGS += -fsanitize=address,undefined
sanitize: clean all

sanitize-demo: CFLAGS += -O0 -g3 -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-recover=address,undefined
sanitize-demo: LDFLAGS += -fsanitize=address,undefined
sanitize-demo: clean all

coverage: CFLAGS += -O0 -g3 --coverage -fprofile-arcs -ftest-coverage
coverage: LDFLAGS += --coverage
coverage: clean all

fuzz: CC = afl-clang-fast
fuzz: CFLAGS += -O0 -g3 -fsanitize=address,undefined -fno-omit-frame-pointer
fuzz: LDFLAGS += -fsanitize=address,undefined
fuzz: clean all

