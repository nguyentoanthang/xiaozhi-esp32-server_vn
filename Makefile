.PHONY: test test-fast test-python help

help:
	@echo "make test-fast   - run all fast unit tests (default)"
	@echo "make test        - alias for test-fast"
	@echo "make test-python - pytest in main/xiaozhi-server"

test: test-fast

test-fast: test-python

test-python:
	cd main/xiaozhi-server && python -m pytest -x -q
