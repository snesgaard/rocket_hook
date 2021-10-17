build_art:
	make -C art

play: build_art
	love .

test: build_art
	love . test
