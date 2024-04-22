#include <stdio.h> // needed for ‘printf’ 
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

void simple_axpy(int n, X_TYPE a, X_TYPE * x, X_TYPE * y){

    printf("(Simple) saxpy of Array of size (%d)\n",n);

    for(int i=0; i<n; i++){
        y[i] = a * x[i] + y[i];
    }
}

void openmp_axpy(int n, X_TYPE a, X_TYPE * x, X_TYPE * y){
    int num_threads = omp_get_max_threads();

    printf("(OpenMP) saxpy of Array of size (%d)\n",n);
    printf("Using %d Threads\n", num_threads);
    #pragma omp parallel for
    for(int i=0; i<n; i++){
        y[i] = a * x[i] + y[i];
    }
}


int main( int argc, char *argv[] )  {

    printf("X_TYPE size is (%d) bytes \n",sizeof (X_TYPE));

    int N;
    /* DUMB bools needed for the argument parsing logic */
    bool openmp = false;
    bool simple = true;
    bool sanity_check = false;
    
    /* VERY DUMB Argument Parsers */
    N = parse_arguments(argc, argv, &simple, &openmp, &sanity_check);

    X_TYPE *sx; /* n is an array of N integers */
    X_TYPE *sy; /* n is an array of N integers */

    sx = (X_TYPE*)malloc(N * sizeof (X_TYPE));
    sy = (X_TYPE*)malloc(N * sizeof (X_TYPE));

    // THIS IS NEW !!!!!!!
    auto sensor = pmt::rapl::Rapl::Create();
        
    /* Simple saxpy */
    /*==============================*/
    if (true == simple)
    {

    //Start the PMT "sensor"
    auto start = sensor->Read();
    
    simple_axpy(N, 2.0, sx, sy);

    //End the PMT "sensor"
    auto end = sensor->Read();

    /// SORRY FOR THE CPP !!!!! BUT WE ARE JUST PRINTING!!!!
    std::cout << "SIZE: " << N <<std::endl;
    std::cout << "RAPL) CPU_TIME: " << pmt::PMT::seconds(start, end) << " s"<< std::endl;
    std::cout << "RAPL) CPU_JOULES: " << pmt::PMT::joules(start, end) << " J" << std::endl;
    std::cout << "RAPL) CPU_WATTS: " << pmt::PMT::watts(start, end) << " W" << std::endl;

    }

    /* OpenMP parallel saxpy */
    /*==============================*/
    if (true == openmp)
    {

    //Start the PMT "sensor"
    auto start = sensor->Read();

    openmp_axpy(N, 2.0, sx, sy);
    
    //End the PMT "sensor"
    auto end = sensor->Read();

    /// SORRY FOR THE CPP !!!!! BUT WE ARE JUST PRINTING!!!!
    std::cout << "SIZE: " << N <<std::endl;
    std::cout << "RAPL) CPU_TIME: " << pmt::PMT::seconds(start, end) << " s"<< std::endl;
    std::cout << "RAPL) CPU_JOULES: " << pmt::PMT::joules(start, end) << " J" << std::endl;
    std::cout << "RAPL) CPU_WATTS: " << pmt::PMT::watts(start, end) << " W" << std::endl;

    }


}
