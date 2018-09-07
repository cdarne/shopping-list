default: start

start:
	elm-app start

build:
	elm-app build

deploy: build
	cd build; now deploy --public --name "shopping-list"

clean:
	rm -Rf elm-stuff

.PHONY: start build deploy clean
