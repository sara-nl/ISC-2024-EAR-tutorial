#include <stdio.h> // needed for ‘printf’ 
#include <stdlib.h> // needed for ‘RAND_MAX’ 
#include <omp.h> // needed for OpenMP 
#include <time.h> // needed for clock() and CLOCKS_PER_SEC etc
#include "helper.h" // local helper header to clean up code
#include <pmt.h> // needed for PMT
#include <pmt/Rapl.h> // needed for RAPL
#include<iostream> // needed for CPP IO ... cout, endl etc etc


#ifdef USE_DOUBLE
typedef double X_TYPE;
#else
typedef float X_TYPE;
#endif

void initialize_matrices(X_TYPE* A, X_TYPE* B, X_TYPE* C, int ROWS, int COLUMNS){
    // Do this in Parallel with OpenMP
    // Needs a seperate seed per thread as rand() is obtaining a mutex and therefore locking each thread.
    unsigned int globalSeed = clock();  
    #pragma omp parallel for
    for (int i = 0; i < ROWS * COLUMNS; i++)
        {
          unsigned int randomState = i ^ globalSeed;
          A[i] = (X_TYPE) rand_r(&randomState) / RAND_MAX;
          B[i] = (X_TYPE) rand_r(&randomState) / RAND_MAX;
          C[i] = 0.0 ;
        }
}

__global__ void simple_matrix_multiply(X_TYPE* D_A, X_TYPE* D_B, X_TYPE* D_C, int ROWS, int COLUMNS){
    
    int local_COLUMN = threadIdx.x + blockIdx.x * blockDim.x;
		int local_ROW = threadIdx.y + blockIdx.y * blockDim.y;
		int local_index = local_COLUMN + local_ROW * ROWS; // Right now this only works for symetric matricies
		int tmp = 0;  
    
    if(local_ROW < ROWS && local_COLUMN < COLUMNS){
			for(int k=0; k<COLUMNS; k++){
				tmp += D_A[local_ROW * ROWS + k] * D_B[k * COLUMNS + local_COLUMN];
			}
			D_C[local_index] = tmp;
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

  /* declare the arrays...  better to do it as 1D arrays for CUDA */

  // First allocated them on the host (CPU)
    X_TYPE* A = (X_TYPE*)malloc((ROWS * COLUMNS) * sizeof(X_TYPE));
    X_TYPE* B = (X_TYPE*)malloc((ROWS * COLUMNS) * sizeof(X_TYPE));
    X_TYPE* C = (X_TYPE*)malloc((ROWS * COLUMNS) * sizeof(X_TYPE));

  // Then Allocate them on the GPUs
  X_TYPE* D_A;
  X_TYPE* D_B;
  X_TYPE* D_C;
  cudaMalloc((void**)&D_A, sizeof( X_TYPE ) * (ROWS * COLUMNS));
  cudaMalloc((void**)&D_B, sizeof( X_TYPE ) * (ROWS * COLUMNS));
  cudaMalloc((void**)&D_C, sizeof( X_TYPE ) * (ROWS * COLUMNS));

  double start = omp_get_wtime();  

  initialize_matrices(A, B, C, ROWS, COLUMNS);
    
  double end = omp_get_wtime(); 
  printf("Init TIME: %f sec\n",(end-start));

    // THIS IS NEW !!!!!!!
  auto GPUsensor = pmt::nvml::NVML::Create();
  auto CPUsensor = pmt::rapl::Rapl::Create();

  /*======================================================================*/
  /*                START of Section of the code that matters!!!          */
  /*======================================================================*/

  /* Simple matrix multiplication */
  /*==============================*/
    int block_size = 512;
    int grid_size = ((ROWS + block_size) / block_size);
    
    //Start the PMT "sensor"
    auto GPUstart = GPUsensor->Read(); // READING the GPU via NVML
    auto CPUstart = CPUsensor->Read(); // READING the CPU via RAPL

    // Transfer data from host to device memory
    cudaMemcpy(D_A, A, sizeof(X_TYPE) * (ROWS * COLUMNS), cudaMemcpyHostToDevice);
    cudaMemcpy(D_B, B, sizeof(X_TYPE) * (ROWS * COLUMNS), cudaMemcpyHostToDevice);
    
    simple_matrix_multiply<<<grid_size,block_size>>>(D_A, D_B, D_C, ROWS, COLUMNS);

   // Transfer data from device to host memory
    cudaMemcpy(C, D_C, sizeof(X_TYPE) * (ROWS * COLUMNS), cudaMemcpyDeviceToHost);


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
    
  /*======================================================================*/
  /*                 END of Section of the code that matters!!!           */
  /*======================================================================*/

 // Deallocate device memory
    cudaFree(D_A);
    cudaFree(D_B);
    cudaFree(D_C);

  // Deallocate host memory
  free(A);
  free(B);
  free(C);
}
