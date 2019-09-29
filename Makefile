.PHONY: test

install:
	mix deps.get

console:
	iex -S mix

docs:
	mix docs

release:
	sed -i '' -e 's/{:batch_loader, "~> [0-9\.]*"}/{:batch_loader, "~> $(VERSION)"}/' README.md && \
	sed -i '' -e 's/@version "[0-9\.]*"/@version "$(VERSION)"/' mix.exs && \
	git add --all && \
	git commit -v -m "Release v$(VERSION)" && \
	git tag "v$(VERSION)"

publish:
	git push && \
	git push --tags && \
	mix hex.publish

format:
	mix format && mix credo

test: format
	iex -S mix test --trace
