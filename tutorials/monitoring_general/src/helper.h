#include <ctype.h> // needed for isdigit
#include <stdio.h> // needed for ‘printf’ 
#include <stdlib.h> // needed for ‘EXIT_FAILURE’ 
#include <string.h> // needed for strcmp
#include <stdbool.h> // needed for bool usage


void print_saxpy_usage()
{
    fprintf(stderr, "saxpy (array size) [-s|-p|-h]\n");
    fprintf(stderr, "\t      Invoke simple implementation of Saxpy (Single precision A X plus Y)\n");
    fprintf(stderr, "\t-s    Invoke simple implementation of Saxpy (Single precision A X plus Y)\n");
    fprintf(stderr, "\t-p    Invoke parallel (OpenMP) implementation of Saxpy (Single precision A X plus Y)\n");
    fprintf(stderr, "\t-h    Display help\n");
}

void print_mat_mul_usage()
{
    fprintf(stderr, "mat_mul (matrix size) [-s|-p|-h]\n");
    fprintf(stderr, "\t      Invoke simple implementation of matrix multiplication\n");
    fprintf(stderr, "\t-s    Invoke simple implementation of matrix multiplication\n");
    fprintf(stderr, "\t-p    Invoke parallel (OpenMP) implementation of matrix multiplication\n");
    fprintf(stderr, "\t-h    Display help\n");
}

bool isNumber(char number[])
{
    int i = 0;

    //checking for negative numbers
    if (number[0] == '-')
        i = 1;
    for (; number[i] != 0; i++)
    {
        //if (number[i] > '9' || number[i] < '0')
        if (!isdigit(number[i]))
            return false;
    }
    return true;
}

int parse_arguments(size_t count, char*  args[], bool *simple, bool *openmp, bool *sanity_check) {
    int N;
    if (count == 1){
        printf("I need (arraysize) as an argument ..... Exiting.\n");
        exit (1);
    }
    for(int i=0; i<count; ++i)
        {   
            if (! strcmp("-s", args[i]))
            {
                *simple = true;
            }
            else if (! strcmp("-p", args[i]))
            {
                *openmp = true;
                *simple = false;
            }
            else if (!strcmp("-h", args[i]))
            {
                if (strstr(args[0],"saxpy"))
                {
                print_saxpy_usage();
                }
                else if (strstr(args[0],"mat_mul"))
                {
                print_mat_mul_usage();
                }
                exit (1);
            }
            else if (isNumber(args[i]))
            {
              sscanf(args[i],"%d", &N);
              *sanity_check = true;
            }
        }
        /* Dumb logic to make sure an array size was passed */
    if (! sanity_check){
        printf("I need (arraysize) as an argument ..... Exiting.\n");
        exit (1);

    }
    return (N);
}