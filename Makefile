all: test main

main: main.c topo_sse.S strcmp2.s
	gcc -g -O3 -std=gnu99 main.c topo_sse.S strcmp2.s -o main

test: test.c topo_sse.S
	gcc -g -O3 -std=gnu99 test.c topo_sse.S -o test
