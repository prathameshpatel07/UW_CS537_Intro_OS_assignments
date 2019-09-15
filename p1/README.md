I have implemented assignment named p1 with the three utlitites saved in each of the files:
1. my-look
2. across
3. my-diff

Description:
1. my-look:

i) I have compared the string and the line in the dictionary with 'strncasecmp' function which is case-insensitive.
ii) For the skeletal of the program, I have followed the instruction given in the assignment page and used fucntion like fopen,fclose, fgets for parsing.

2. across:

i) Before comparing with the function 'strncmp' (Case-insensitivity), I have filtered the string by checking if there exists an Capital or non-alphanumeric characters.
ii) For the skeletal of the program, I have followed the instruction given in the assignment page and used fucntion like fopen,fclose, fgets for parsing.

3. my-diff:

i) I have used eofl1 and eofl2 (End-of-the-Line) variables to indicate end of lines for both file reads.
ii) String comparison is only done if eofl1 or eofl2 along with maintaining a flag to check if the sequence of string match has been broken.
iii) Incase, the eofl is reached for one line, the content for the lines thereafter in the next lines is displayed.
