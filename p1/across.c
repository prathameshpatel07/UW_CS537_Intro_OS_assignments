#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int main(int argc, char *argv[]) {
        if ((argc < 4 || argc > 5)) {
                printf("across: invalid number of arguments\n");
                exit(1);
        }
        char *str1 = argv[1];
        int  start = atoi(argv[2]);
        int  total = atoi(argv[3]);
        char *fname = argv[4];
        FILE *fp;

        if (start+strlen(str1)-1 >= total) {
                printf("across: invalid position\n");
                exit(1);
        }
        if (argv[4] == NULL) {
                fp = fopen("/usr/share/dict/words", "r");
        } else {
                fp = fopen(fname, "r");
                if (fp == NULL) {
                        printf("across: cannot open file\n");
                        exit(1); }
        }
        char str2[100];
        int result;
        int notcomp;
        while (fgets(str2, 100, fp) != NULL) {
                result = 1;
                int j;
                for (j = 0; j < strlen(str2)-1; j++) {
                        if (!isalpha(str2[j]) || !islower(str2[j])) {
                                        notcomp = 1;
                                        break;
                        } else {
                                notcomp = 0;
                        }
                }
                if ((strlen(str2)-1 == total) && (notcomp == 0)) {
                        result = strncmp(str1, str2+start, strlen(str1));
                        if (result == 0)
                                printf("%s", str2);}
        }
        fclose(fp);
return 0;
}
