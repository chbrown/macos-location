all: location-logger

location-logger: location-logger.swift
	xcrun -sdk macosx swiftc $< -O -o $@

install: location-logger
	cp $< /usr/local/bin/location-logger
