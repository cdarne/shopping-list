default: start

start:
	elm-app start

build:
	elm-app build

build-github: build
	sed -i '' 's|/static/|/shopping-list/static/|g' build/index.html
	sed -i '' 's|/service-worker.js|/shopping-list/service-worker.js|g' build/static/js/main.*.js

deploy: build-github
	gh-pages -d build

deploy-now: build
	cp now.json build/
	cd build; now deploy --public && now alias

clean:
	rm -Rf elm-stuff

.PHONY: start build build-github deploy deploy-now clean
