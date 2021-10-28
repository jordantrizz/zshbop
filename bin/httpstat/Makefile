.PHONY: test build

test:
	@bash httpstat_test.sh

clean:
	rm -rf build dist *.egg-info

build:
	python setup.py build

build-dist:
	python setup.py sdist bdist_wheel

publish: build-dist
	python -m twine upload --skip-existing $(shell ls -t dist/*.whl | head -1)
