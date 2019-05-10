#include <stdlib.h>
#include <math.h>
#include <stdio.h>

#ifndef VECTOR_SIZE
#define VECTOR_SIZE (1024 * 1024)
#endif

int main() {
    long *v1 = calloc(1, sizeof(long) * VECTOR_SIZE);
    long *v2 = calloc(1, sizeof(long) * VECTOR_SIZE);
    long *v3 = calloc(1, sizeof(long) * VECTOR_SIZE);
    
    for(int i = 0; i < VECTOR_SIZE; i++ )
    {
        v1[i] = i;
        v2[i] = i;
    } 
    
    for(int i = 0; i < VECTOR_SIZE; i++) {
        v3[i] = v1[i] + v2[i];
    }

    long sum = 0;
    for(int i=0; i < VECTOR_SIZE; i++) {
        sum += v3[i];
    }
    printf("final result: %ld\n", sum / VECTOR_SIZE);
}
