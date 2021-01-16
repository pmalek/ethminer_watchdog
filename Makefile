shellcheck:
	@./scripts/shellcheck.sh

markdownlint: mdl

mdl:
	mdl --style .markdownlint/style.rb \
		README.md
