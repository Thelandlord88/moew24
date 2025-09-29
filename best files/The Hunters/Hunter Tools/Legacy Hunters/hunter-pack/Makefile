.PHONY: hunt hunt-strict hunt-warn thinker clean
hunt:
	@bash ./hunt.sh
hunt-strict:
	@STRICT=1 bash ./hunt.sh
hunt-warn:
	@STRICT=0 bash ./hunt.sh
thinker:
	@node thinker/index.mjs
clean:
	@rm -rf __reports/hunt __ai/thinker var
