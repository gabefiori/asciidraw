OUTPUT = asciidraw

build:
	odin build main.odin -file -o:speed -out:$(OUTPUT) -vet -vet-cast -strict-style
