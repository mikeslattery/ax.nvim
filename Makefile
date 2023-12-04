# Makefile for a Neovim plugin.

# Variables
NAME = ax
NVIM = nvim
TEST_DIR = ./test
PLUGINS_DIR = ./test/plenary
MODEL = gpt-4-1106-preview
PROMPT = "\
	INSTRUCTION:\
	Convert the above vim plugin help file to direct *raw* markdown.\
	Do not generate a table of contents.\
	Have an empty line after markdown headers.\
	Only generate the raw markdown, not any enclosure or commentary.\
	"

-include .env

all: test/.last README.md

.PHONY: all test manual helptags continous helpdoc

# Test target
test: test/.last

test/.last: test/*.lua test/plenary/* lua/$(NAME)/* Makefile
	@$(NVIM) \
		--headless \
		-c "PlenaryBustedDirectory $(TEST_DIR)/ {minimal_init = '$(PLUGINS_DIR)/minimal_init.vim'}" \
		-c "qa!"
	@touch test/.last

manual:
	@$(NVIM) \
		-c "PlenaryBustedDirectory $(TEST_DIR)/ {minimal_init = '$(PLUGINS_DIR)/minimal_init.vim'}"

continuous:
	@while true; do make -s; sleep 2; done

helptags:
	@$(NVIM) \
		--headless \
		-c "helptags doc" \
		-c "qa!"

# doc/$(NAME).txt: lua/$(NAME)/init.lua lua test/$(NAME)_spec.lua lua
# Not depenency checking because we don't want it automated
helpdoc:
	@doc/gendoc.sh "$(NAME)"

README.md: doc/$(NAME).txt Makefile
	@openai api chat.completions.create -m "$(MODEL)" \
		-g user "`cat doc/$(NAME).txt` `echo $(PROMPT)`" \
		> README.md

