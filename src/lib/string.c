#include "../include/string.h"

void* memset(void* dest, int val, size_t len) {
    unsigned char* ptr = (unsigned char*)dest;
    while (len-- > 0)
        *ptr++ = val;
    return dest;
}

void* memcpy(void* dest, const void* src, size_t len) {
    const unsigned char* s = (const unsigned char*)src;
    unsigned char* d = (unsigned char*)dest;
    while (len--)
        *d++ = *s++;
    return dest;
} 