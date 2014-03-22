#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>



void die_errno(char *message, ...)
{
    va_list ap;
    va_start(ap, message);
    vfprintf(stderr, message, ap);
    va_end(ap);
    fprintf(stderr, ": %s\n", strerror(errno));
    exit(1);
}

void append(char ***lines, int *alloc, int *used, char *line)
{
    if (*used == *alloc) {
        *alloc *= 2;
        *lines = realloc(*lines, *alloc * sizeof(char*));
    }
    (*lines)[(*used)++] = line;
}

char **load(char *path, int *count)
{
    int alloc = 10;
    int used = 0;
    char **lines = malloc(sizeof(char*) * alloc);


    int fd = open(path, O_RDONLY);
    if (fd < 0) {
        die_errno("Failed to open file");
    }
    struct stat st;
    if (fstat(fd, &st) == -1)
        die_errno("Failed to stat file");
    
    char *data = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    char *end = data + st.st_size;
    char *line_start = data;
    char *c;
    for (c = data; c < end; ++c) {
        if (*c == '\n') {
            int line_len = c - line_start;
            char *line = strndup(line_start, line_len);
            append(&lines, &alloc, &used, line);
            line_start = c + 1;
        }
    }
    if (line_start != c) {
        int line_len = c - line_start;
        char *line = strndup(line_start, line_len);
        append(&lines, &alloc, &used, line);
    }

    *count = used;

    append(&lines, &alloc, &used, NULL);

    munmap(data, st.st_size);
    return lines;
}

enum mode {
    MODE_PLAIN,
    MODE_STUPID_ASM,

    MODE_TOPO,
    MODE_TOPO_TABLE,

    MODE_TOPO_ASM,
};


int topo(const void *a, const void *b)
{
    const unsigned char *sa = *(unsigned char **)a;
    const unsigned char *sb = *(unsigned char **)b;
    while (*sa && *sb) {
        unsigned char ca, cb;
        if (*sa == '/')
            ca = 1;
        else if (*sa < '/')
            ca = *sa - 1;
        else
            ca = *sa;

        if (*sb == '/')
            cb = 1;
        else if (*sb < '/')
            cb = *sb - 1;
        else
            cb = *sb;

        if (ca < cb)
            return -1;
        else if (ca > cb)
            return 1;
        else {
            sa ++;
            sb ++;
        }
    }
    if (*sa)
        return 1;
    if (*sb)
        return -1;
    return 0;
}

unsigned char topo_key_table[256] = {
    0, 47, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 1, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255
};

int topo_table(const void *a, const void *b)
{
    const unsigned char *sa = *(unsigned char **)a;
    const unsigned char *sb = *(unsigned char **)b;
    while (*sa && *sb) {
        unsigned char ca = topo_key_table[*sa];
        unsigned char cb = topo_key_table[*sb];

        if (ca < cb)
            return -1;
        else if (ca > cb)
            return 1;
        else {
            sa ++;
            sb ++;
        }
    }
    if (*sa)
        return 1;
    if (*sb)
        return -1;
    return 0;
}

int plain(const void *a, const void *b)
{
    const char *sa = *(char **)a;
    const char *sb = *(char **)b;
    return strcmp(sa, sb);
}

int strcmp2(const char *a, const char *b);

int stupid_asm(const void *a, const void *b)
{
    const char *sa = *(char **)a;
    const char *sb = *(char **)b;
    return strcmp2(sa, sb);
}

#define SHOULD_PRINT 0

int topo_sse2(const void *a, const void *b);

int main(int argc, char** argv) {
    int count;
    char **lines = load("files", &count);
    int mode = MODE_PLAIN;

    fprintf(stderr, "Read %d lines\n", count);

    if (argc >= 2) {
        if (!strcmp(argv[1], "plain"))
            mode = MODE_PLAIN;
        else if (!strcmp(argv[1], "topo"))
            mode = MODE_TOPO;
        else if (!strcmp(argv[1], "topo_table"))
            mode = MODE_TOPO_TABLE;
        else if (!strcmp(argv[1], "stupid"))
            mode = MODE_STUPID_ASM;
        else if (!strcmp(argv[1], "asm"))
            mode = MODE_TOPO_ASM;
    }

    for (int i = 0; i < 10; ++i) {
        char **dup = malloc(count * sizeof(char*));
        memcpy(dup, lines, count * sizeof(char*));
        switch(mode) {
        case MODE_PLAIN:
            qsort(dup, count, sizeof(char*), plain);
            break;
        
        case MODE_TOPO:
            qsort(dup, count, sizeof(char*), topo);
            break;

        case MODE_TOPO_TABLE:
            qsort(dup, count, sizeof(char*), topo_table);
            break;

        case MODE_STUPID_ASM:
            qsort(dup, count, sizeof(char*), stupid_asm);
            break;

        case MODE_TOPO_ASM:
            qsort(dup, count, sizeof(char*), topo_sse2);
            break;
        }
        if (i == 0 && SHOULD_PRINT)
            for (int j = 0; j < count; ++j)
                printf("%s\n", dup[j]);

        free(dup);
    }
}
