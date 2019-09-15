#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
        if (argc == 1 || argc > 3) {
                printf("my-look: invalid number of arguments\n");
                exit(1);
        }
        char *str1 = argv[1];
        char *fname = argv[2];
        FILE *fp;
        if (argv[2] == NULL) {
                fp = fopen("/usr/share/dict/words", "r");
        } else {
                fp = fopen(fname, "r");
                if (fp == NULL) {
                        printf("my-look: cannot open file\n");
                        exit(1);
                }
        }
        char str2[100];
        int result;
        while (fgets(str2, 100, fp) != NULL) {
                result = strncasecmp(str1, str2, strlen(str1));
                if (result == 0)
                    printf("%s", str2);
        }
        fclose(fp);
return 0;
}
