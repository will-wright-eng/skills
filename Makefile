SKILLS ?=

.DEFAULT_GOAL := help
.PHONY: help check drift validate scan

help: ## Show targets (scope any target with SKILLS="a b")
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

check: validate drift scan ## Run validate, drift, and scan

drift: ## Diff replicated skills against upstream
	bash scripts/check_replicated_skills.sh --stat $(SKILLS)

validate: ## Validate skills against the agentskills.io spec
	bash scripts/validate_skill.sh $(if $(SKILLS),$(addprefix skills/,$(SKILLS)),skills/*/)

scan: ## Static security scan (fails on HIGH/CRITICAL)
	bash scripts/scan_skills.sh $(SKILLS)
