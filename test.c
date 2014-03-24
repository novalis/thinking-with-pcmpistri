#include <assert.h>
#include <stdio.h>
#include <string.h>

/* put the string at the end of a block, so that we can make sure the
 * block-boundary code works */

char *xstrndup(const char* s) {
    const int SIZE = 4088;
    int len = strlen(s);
    char *ret = malloc(SIZE);
    strcpy(ret + SIZE - (len + 1), s);
    return ret + SIZE - (len + 1);
}

int topo_sse(const void *a, const void *b);
int main(int argc, char** argv) {
    char *tilde = ".git/COMMIT_EDITMSG~";
    char *notilde = ".git/COMMIT_EDITMSG";

    char *dir = "dir";
    char *subdir = "dir/fleem";
    char *nondira = "dir-fleem";
    char *nondirb = "dir=fleem";

    char *data1 = ".git/COMMIT_EDITMSG";
    char *data2 = "samples/kprobes";

    char* data3 = "Documentation/arm/Samsung/GPIO.txt";
    char* data4 = "Documentation/arm/Samsung-S3C24XX";

    char *a = "abcdefgh012347";
    char *b = "abcdefgh01234X";

    char *pack = xstrndup(".git/objects/pack/pack-3c2034acfef6c89728776a312378209d290c7094.pack");
    char *idx = xstrndup(".git/objects/pack/pack-3c2034acfef6c89728776a312378209d290c7094.idx");

    assert(topo_sse(&idx, &pack) < 0);
    assert(topo_sse(&pack, &idx) > 0);

    assert(topo_sse(&data3, &data4) < 0);
    assert(topo_sse(&data4, &data3) > 0);
    assert(topo_sse(&data4, &data4) == 0);

    assert(topo_sse(&data2, &data1) > 0);
    assert(topo_sse(&data1, &data2) < 0);

    assert(topo_sse(&nondira, &subdir) > 0);
    assert(topo_sse(&subdir, &nondira) < 0);

    assert(topo_sse(&nondirb, &subdir) > 0);
    assert(topo_sse(&subdir, &nondirb) < 0);

    assert(topo_sse(&subdir, &dir) > 0);
    assert(topo_sse(&dir, &subdir) < 0);
    assert(topo_sse(&dir, &dir) == 0);

    assert(topo_sse(&tilde, &notilde) > 0);
    assert(topo_sse(&notilde, &tilde) < 0);

    assert(topo_sse(&a, &a) == 0);
    assert(topo_sse(&a, &b) < 0);
    assert(topo_sse(&b, &a) > 0);

}
