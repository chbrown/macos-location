all: bin/location-logger

clean:
	rm -f bin/location-logger

bin/location-logger: location-logger.swift
	@mkdir -p $(@D)
	xcrun -sdk macosx swiftc $< -O -o $@

install: bin/location-logger
	cp $< /usr/local/bin/location-logger

test:
	swiftformat --lint *.swift
	swiftlint lint *.swift
