PREFIX := /usr

SRC := $(wildcard *.sh)

all: $(SRC)

install: all
	install -m 755 -d $(PREFIX)/lib/ubash
	install -m 755 $(SRC) $(PREFIX)/lib/ubash

clean:
