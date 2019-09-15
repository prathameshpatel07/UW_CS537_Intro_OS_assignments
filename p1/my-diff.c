#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
        if (argc > 3) {
                printf("my-diff: invalid number of arguments\n");
                exit(1);
        }
        char *fnameA = argv[1];
        char *fnameB = argv[2];
        FILE *fp1;
        FILE *fp2;

                fp1 = fopen(fnameA, "r");
                fp2 = fopen(fnameB, "r");
                if (fp1 == NULL || fp2 == NULL) {
                        printf("my-diff: cannot open file\n");
                        exit(1); }
        char str1[100];
        char str2[100];
        int result;
        int i = 0;
        int flag = 1;
        int eofl1 = 0;
        int eofl2 = 0;
        while (1) {
                eofl1 = (fgets(str1, 100, fp1) == NULL)? 1: 0;
                eofl2 = (fgets(str2, 100, fp2) == NULL)? 1: 0;
                if (eofl1 && eofl2) {
                        break;
                }
                i++;
                result = eofl1 || eofl2 ? 1 : strcmp(str1, str2);
                        if (result != 0) {
                               if (flag == 1) {
                                   printf("%d\n", i);
                                   flag = 0;
                               }
                                if (eofl1 == 0) printf("< %s", str1);
                                if (eofl2 == 0) printf("> %s", str2);
                        } else {
                                flag = 1;
                        }
        }
        fclose(fp1);
        fclose(fp2);
return 0;
}
