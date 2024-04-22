#include <stdio.h> // needed for ‘printf’ 
#include <stdlib.h> // needed for ‘RAND_MAX’ 
#include <omp.h> // needed for OpenMP 
#include <time.h> // needed for clock() and CLOCKS_PER_SEC etc
#include "helper.h" // local helper header to clean up code
#include <pmt.h> // needed for PMT
#include <pmt/Rapl.h> // needed for RAPL
#include <iostream> // needed for CPP IO ... cout, endl etc etc


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

    // THIS IS NEW !!!!!!!
    auto sensor = pmt::rapl::Rapl::Create();

  /* Simple matrix multiplication */
  /*==============================*/
  if (true == simple)
  {
    //Start the PMT "sensor"
    auto start = sensor->Read();

    simple_matrix_multiply(A, B, C, ROWS, COLUMNS);
    
    //End the PMT "sensor"
    auto end = sensor->Read();

    /// SORRY FOR THE CPP !!!!! BUT WE ARE JUST PRINTING!!!!
    std::cout << "SIZE: " << N <<std::endl;
    std::cout << "(RAPL) CPU_TIME: " << pmt::PMT::seconds(start, end) << " s"<< std::endl;
    std::cout << "(RAPL) CPU_JOULES: " << pmt::PMT::joules(start, end) << " J" << std::endl;
    std::cout << "(RAPL) CPU_WATTS: " << pmt::PMT::watts(start, end) << " W" << std::endl;


  }

  /* OpenMP parallel matrix multiplication */
  /*=======================================*/
  if (true == openmp)
  {
    //Start the PMT "sensor"
    auto start = sensor->Read();

    openmp_matrix_multiply(A, B, C, ROWS, COLUMNS);
    
    //End the PMT "sensor"
    auto end = sensor->Read();

    /// SORRY FOR THE CPP !!!!! BUT WE ARE JUST PRINTING!!!!
    std::cout << "SIZE: " << N <<std::endl;
    std::cout << "(RAPL) CPU_TIME: " << pmt::PMT::seconds(start, end) << " s"<< std::endl;
    std::cout << "(RAPL) CPU_JOULES: " << pmt::PMT::joules(start, end) << " J" << std::endl;
    std::cout << "(RAPL) CPU_WATTS: " << pmt::PMT::watts(start, end) << " W" << std::endl;

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
