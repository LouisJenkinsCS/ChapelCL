all:
	clang -framework opencl vecAdd.c -o vecAdd -DVECTOR_SIZE=1000000 -DCL_SILENCE_DEPRECATION -O3
	clang -framework opencl vecAddCPU.c -DVECTOR_SIZE=1000000 -O3 -o vecAddCPU

clean:
	rm vecAdd vecAddCPU
