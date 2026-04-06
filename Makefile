.PHONY: precommit precommit-djlint

precommit:
	pre-commit run --all-files

precommit-djlint:
	pre-commit run djlint-django --all-files
