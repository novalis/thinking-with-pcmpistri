#include <assert.h>
#include <stdio.h>
#include <string.h>

int topo_sse2(const void *a, const void *b);
int main(int argc, char** argv) {
    char *tilde = strdup(".git/COMMIT_EDITMSG~");
    char *notilde = strdup(".git/COMMIT_EDITMSG");

    char *dir = strdup("dir");
    char *subdir = strdup("dir/fleem");
    char *nondira = strdup("dir-fleem");
    char *nondirb = strdup("dir=fleem");

    char *data1 = strdup(".git/COMMIT_EDITMSG");
    char *data2 = strdup("samples/kprobes");

    char* data3 = strdup("Documentation/arm/Samsung/GPIO.txt");
    char* data4 = strdup("Documentation/arm/Samsung-S3C24XX");

    assert(topo_sse2(&data3, &data4) == -1);
    assert(topo_sse2(&data4, &data3) == 1);

    assert(topo_sse2(&data2, &data1) == 1);
    assert(topo_sse2(&data1, &data2) == -1);

    assert(topo_sse2(&nondira, &subdir) == 1);
    assert(topo_sse2(&subdir, &nondira) == -1);

    assert(topo_sse2(&nondirb, &subdir) == 1);
    assert(topo_sse2(&subdir, &nondirb) == -1);

    assert(topo_sse2(&subdir, &dir) == 1);
    assert(topo_sse2(&dir, &subdir) == -1);
    assert(topo_sse2(&dir, &dir) == 0);

    assert(topo_sse2(&tilde, &notilde) == 1);
    assert(topo_sse2(&notilde, &tilde) == -1);


    char *a = strdup("abcdefgh012347");
    char *b = strdup("abcdefgh01234X");

    assert(topo_sse2(&a, &a) == 0);
    assert(topo_sse2(&a, &b) == -1);
    assert(topo_sse2(&b, &a) == 1);

}
