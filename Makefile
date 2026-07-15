# cut is necessary for Cygwin
PLATFORM_OS := $(shell uname | cut -d_ -f1)

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
	clang -o $@ -c common.c $(CFLAGS)

imgify.o: imgify.h
	clang -o $@ -c imgify.c $(CFLAGS)

bin2png: common.o imgify.o
	clang -o $@ bin2png.c $^ $(CFLAGS) $(LDFLAGS)

png2bin: common.o imgify.o
	clang -o $@ png2bin.c $^ $(CFLAGS) $(LDFLAGS)
	
.PHONY: debug release sanitize sanitize-demo

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
