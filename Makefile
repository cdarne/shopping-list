default: start

start:
	elm-app start

build:
	elm-app build

deploy: build
	cp now.json build/
	cd build; now deploy --public && now alias

clean:
	rm -Rf elm-stuff

.PHONY: start build deploy clean
