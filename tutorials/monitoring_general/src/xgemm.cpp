#include <stdio.h> // needed for ‘printf’ 
#include <stdlib.h> // needed for ‘RAND_MAX’ 
#include <omp.h> // needed for OpenMP 
#include <time.h> // needed for clock() and CLOCKS_PER_SEC etc
#include "helper.h" // local helper header to clean up code

#ifdef USE_DOUBLE
typedef double X_TYPE;
#else
typedef float X_TYPE;
#endif

void initialize_matrices(X_TYPE** A, X_TYPE** B, X_TYPE** C, int ROWS, int COLUMNS){
    for (int i = 0 ; i < ROWS ; i++)
    {
        for (int j = 0 ; j < COLUMNS ; j++)
        {
            A[i][j] = (X_TYPE) rand() / RAND_MAX ;
            B[i][j] = (X_TYPE) rand() / RAND_MAX ;
            C[i][j] = 0.0 ;
        }
    }
}

void simple_matrix_multiply(X_TYPE** A, X_TYPE** B, X_TYPE** C, int ROWS, int COLUMNS){
    
    printf("(Simple) Matix Multiplication of 2D matricies of equal sizes (%d, %d)\n",ROWS,COLUMNS);

    for(int i=0;i<ROWS;i++)
    {
        for(int j=0;j<COLUMNS;j++)
        {
            for(int k=0;k<COLUMNS;k++)
            {
                C[i][j] += A[i][k]*B[k][j];
            }
        }
    }
}

void openmp_matrix_multiply(X_TYPE** A, X_TYPE** B, X_TYPE** C, int ROWS, int COLUMNS){
    
    int num_threads = omp_get_max_threads();
    
    printf("(OpenMP) Matix Multiplication of 2D matricies of equal sizes (%d, %d)\n",ROWS,COLUMNS);
    printf("Using %d Threads\n", num_threads);
    
    #pragma omp parallel for 
    for (int i = 0; i < ROWS; ++i) 
    {
        for (int j = 0; j < COLUMNS; ++j) 
        {
            for (int k = 0; k < COLUMNS; ++k) 
            {
                C[i][j] = C[i][j] + A[i][k] * B[k][j];
            }
        }
    }
}


int main( int argc, char *argv[] )  {
    
    printf("X_TYPE size is (%d) bytes \n",sizeof (X_TYPE));

  int ROWS;
  int COLUMNS;
  int N;

  double time_taken=0;
  
  /* DUMB bools needed for the argument parsing logic */
  bool openmp = false;
  bool simple = true;
  bool sanity_check = false;
  
  /* VERY DUMB Argument Parsers */
  N = parse_arguments(argc, argv, &simple, &openmp, &sanity_check);
  ROWS = N;
  COLUMNS = N;
  /* declare the arrays */
  X_TYPE** A = (X_TYPE**)malloc(ROWS * sizeof( X_TYPE* ));
  X_TYPE** B = (X_TYPE**)malloc(ROWS * sizeof( X_TYPE* ));
  X_TYPE** C = (X_TYPE**)malloc(ROWS * sizeof( X_TYPE* ));

    for (int i =0; i <ROWS; i++)
    {
        A[i] = (X_TYPE*)malloc(COLUMNS * sizeof(X_TYPE));
        B[i] = (X_TYPE*)malloc(COLUMNS * sizeof(X_TYPE));
        C[i] = (X_TYPE*)malloc(COLUMNS * sizeof(X_TYPE));
    }

  /*======================================================================*/
  /*                START of Section of the code that matters!!!          */
  /*======================================================================*/

  /* initialize the arrays */
  initialize_matrices(A, B, C, ROWS, COLUMNS);

  /* Simple matrix multiplication */
  /*==============================*/
  if (true == simple)
  {
    clock_t t; // declare clock_t (long type)
    t = clock(); // start the clock
    
    simple_matrix_multiply(A, B, C, ROWS, COLUMNS);
    
    t = clock() - t; // stop the clock

    time_taken = ((double)t)/CLOCKS_PER_SEC; // convert to seconds (and long to double)
    printf("SIZE: %d \n",ROWS);
    printf("TIME: %f s\n",time_taken);
  }



  /* OpenMP parallel matrix multiplication */
  /*=======================================*/
  if (true == openmp)
  {
    // omp_get_wtime needed here because clock will sum up time for all threads
    double start = omp_get_wtime();  

    openmp_matrix_multiply(A, B, C, ROWS, COLUMNS);
    
    double end = omp_get_wtime(); 
    time_taken = (end-start);
    printf("SIZE: %d \n",ROWS);
    printf("TIME: %f s\n",time_taken);    
  }

  /*======================================================================*/
  /*                 END of Section of the code that matters!!!           */
  /*======================================================================*/

  /* deallocate the arrays */
  for (int i=0; i<ROWS; i++)
  {
    free(A[i]);
    free(B[i]);
    free(C[i]);
  }
  free(A);
  free(B);
  free(C);
}
