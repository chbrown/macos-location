INSTALL ?= install
prefix ?= /usr/local
bindir ?= $(prefix)/bin
CFLAGS := -O

all: bin/location-logger

bin/location-logger: $(wildcard *.swift)
	@mkdir -p $(@D)
	xcrun -sdk macosx swiftc $+ $(CFLAGS) -o $@

install: bin/location-logger
	$(INSTALL) $< $(DESTDIR)$(bindir)

uninstall:
	rm -f $(DESTDIR)$(bindir)/location-logger

clean:
	rm -f bin/location-logger

test:
	swiftformat --lint *.swift
	swiftlint lint *.swift
