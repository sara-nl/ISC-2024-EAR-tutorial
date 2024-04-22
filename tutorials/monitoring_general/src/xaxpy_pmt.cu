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

__global__ void gpu_axpy(int n, X_TYPE a, X_TYPE * x, X_TYPE * y) {
    
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    
    // Handling arbitrary vector size
    if (tid < n){
        y[tid] = a * x[tid] + y[tid];
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

    X_TYPE *d_sx; /* n is an array of N integers */
    X_TYPE *d_sy; /* n is an array of N integers */

    X_TYPE a = 2.0;
    // Allocate Host memory 
    X_TYPE* sx = (X_TYPE*)malloc(N * sizeof(X_TYPE));
    X_TYPE* sy = (X_TYPE*)malloc(N * sizeof(X_TYPE));

    // Allocate device memory 
    cudaMalloc((void**)&d_sx, sizeof(X_TYPE) * N);
    cudaMalloc((void**)&d_sy, sizeof(X_TYPE) * N);

    // THIS IS NEW !!!!!!!
    auto GPUsensor = pmt::nvml::NVML::Create();
    auto CPUsensor = pmt::rapl::Rapl::Create();

    /* Simple saxpy */
    /*==============================*/
    if (true == simple)
    {

        int block_size = 512;
        int grid_size = ((N + block_size) / block_size);
        
        //Start the PMT "sensor"
        auto GPUstart = GPUsensor->Read(); // READING the GPU via NVML
        auto CPUstart = CPUsensor->Read(); // READING the CPU via RAPL
        
        // Transfer data from host to device memory
        cudaMemcpy(d_sx, sx, sizeof(X_TYPE) * N, cudaMemcpyHostToDevice);
        cudaMemcpy(d_sy, sy, sizeof(X_TYPE) * N, cudaMemcpyHostToDevice);

        gpu_axpy<<<grid_size,block_size>>>(N, a, d_sx, d_sy);

        cudaMemcpy(sy, d_sy, sizeof(X_TYPE) * N, cudaMemcpyDeviceToHost);

        //Start the PMT "sensor"
        auto GPUend = GPUsensor->Read();
        auto CPUend = CPUsensor->Read();

        std::cout << "SIZE: " << N << std::endl;
        std::cout << "(RAPL) CPU_TIME: " << pmt::PMT::seconds(CPUstart, CPUend) << " | (NVML) GPU_TIME: " << pmt::PMT::seconds(GPUstart, GPUend) << " s"<< std::endl;
        std::cout << "(RAPL) CPU_JOULES: " << pmt::PMT::joules(CPUstart, CPUend) << " | (NVML) GPU_JOULES: " << pmt::PMT::joules(GPUstart, GPUend) << " J"<< std::endl;
        std::cout << "(RAPL) CPU_WATTS: " << pmt::PMT::watts(CPUstart, CPUend) << " | (NVML) GPU_WATTS: " << pmt::PMT::watts(GPUstart, GPUend) << " W"<< std::endl;
        std::cout << "Total TIME: " << (pmt::PMT::seconds(CPUstart, CPUend) + pmt::PMT::seconds(GPUstart, GPUend))*0.5 << " s"<< std::endl;
        std::cout << "Total JOULES: " << (pmt::PMT::joules(CPUstart, CPUend) + pmt::PMT::joules(GPUstart, GPUend)) << " J"<< std::endl;
        std::cout << "Total WATTS: " << (pmt::PMT::watts(CPUstart, CPUend) + pmt::PMT::watts(GPUstart, GPUend)) << " W"<< std::endl;
    
    }
    /* OpenMP parallel saxpy */
    /*==============================*/
    if (true == openmp)
    {

    // omp_get_wtime needed here because clock will sum up time for all threads
    double start = omp_get_wtime();  

    openmp_axpy(N, 2.0, sx, sy);
    
    double end = omp_get_wtime(); 
    printf("TIME: %f sec\n",(end-start));

    }


}
