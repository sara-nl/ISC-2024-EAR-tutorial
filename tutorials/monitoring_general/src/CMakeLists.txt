include_directories(${PROJECT_SOURCE_DIR}/src/)
include(ExternalProject)


find_package(OpenMP REQUIRED)

if (OPENMP_FOUND)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")


# Need this Library to help things out
add_library(HELPER_LIB INTERFACE)

## Here is where you want to add the sources....
set(applications "xgemm;xaxpy")


if (ENABLE_PMT)
    message(STATUS "Looking for pmt")
    find_library(PMT_LIBRARY NAMES pmt)
    if (PMT_LIBRARY)
        message(STATUS "Looking for pmt - found")
    else()
        message(STATUS "Looking for pmt - not found\n Configuring PMT to be built locally ")

        set(PMT_CONFIG_ARGS "-DCMAKE_INSTALL_PREFIX=${PROJECT_SOURCE_DIR}/pmt;-DBUILD_RAPL_PMT=1")
        if (ENABLE_CUDA)
            set(PMT_CONFIG_ARGS "${PMT_CONFIG_ARGS};-DBUILD_RAPL_PMT=1;-DBUILD_NVML_PMT=1")
        endif()
        if (ENABLE_HIP)
            set(PMT_CONFIG_ARGS "${PMT_CONFIG_ARGS};-DBUILD_RAPL_PMT=1;-DBUILD_ROCM_PMT=1")
        endif()
        message(STATUS "PMT will be configured with these arguments: ")
        message(STATUS "${PMT_CONFIG_ARGS} ")

        ExternalProject_Add(PMT_LIBRARY
	    INSTALL_DIR			"${PROJECT_SOURCE_DIR}/pmt"
        GIT_REPOSITORY      "https://git.astron.nl/RD/pmt.git" 
        GIT_TAG             f2c9854f5f0458254fa82c105d6f20ddc058f658
        CMAKE_ARGS          "${PMT_CONFIG_ARGS}"
	    )
        include_directories(${PROJECT_SOURCE_DIR}/pmt/include)
        link_directories(${PROJECT_SOURCE_DIR}/pmt/lib)
        link_directories(${PROJECT_SOURCE_DIR}/pmt/lib64)
        
        # just to go a bit Nuclear if we are running into EESSI compat layer issues.
        set(CMAKE_BUILD_RPATH "${PROJECT_SOURCE_DIR}/pmt/lib64" "${PROJECT_SOURCE_DIR}/pmt/lib")
        set(CMAKE_INSTALL_RPATH "${PROJECT_SOURCE_DIR}/pmt/lib64" "${PROJECT_SOURCE_DIR}/pmt/lib")

    endif()

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -O3 -fpermissive")

    list(TRANSFORM applications APPEND "_pmt")
    endif()


if (ENABLE_CUDA)

    enable_language(C CXX CUDA)
    set(CMAKE_CUDA_FLAGS "-Xcompiler=-fopenmp -gencode arch=compute_80,code=sm_80 -lineinfo --ptxas-options=-v --disable-warnings")
    set(source_suffixs ".cpp;.cu")

elseif(ENABLE_HIP)
    list(APPEND CMAKE_PREFIX_PATH /opt/rocm/hip /opt/rocm)

    enable_language(C CXX HIP)
    find_package(hip REQUIRED)

    set(HIP_PATH "/opt/rocm/hip" CACHE PATH "Path to which HIP has been installed")
    set(CMAKE_HIP_FLAGS "--offload-arch=gfx90a -fopenmp")

    set(CMAKE_CXX_COMPILER ${HIP_HIPCC_EXECUTABLE})
    set(CMAKE_CXX_LINKER   ${HIP_HIPCC_EXECUTABLE})

    set(source_suffixs ".cpp;.hip")

else()
    set(source_suffixs ".cpp")
endif()


foreach(application IN LISTS applications)
    foreach(source_suffix IN LISTS source_suffixs)

        if(source_suffix MATCHES ".cu")
            set(executable_suffix "_gpu")
        elseif(source_suffix MATCHES ".hip")
            set(executable_suffix "_gpu")
        else()
            set(executable_suffix "")
        endif()

        # Add the corresponding suffix per language
        string(CONCAT source "${application}" "${source_suffix}")

        #Double Precision
        string(REGEX REPLACE "^x" "d" executable "${application}")
        string(APPEND executable "${executable_suffix}")

        add_executable("${executable}" "${source}")
        target_link_options("${executable}" PUBLIC "-fopenmp")
        target_link_libraries("${executable}" HELPER_LIB)
        if (ENABLE_PMT)
            target_link_libraries("${executable}" pmt)
        endif()
        target_compile_definitions("${executable}" PUBLIC USE_DOUBLE)

        install(TARGETS "${executable}" RUNTIME DESTINATION ${PROJECT_SOURCE_DIR}/bin)

        #Single Precision
        string(REGEX REPLACE "^x" "s" executable "${application}")
        string(APPEND executable "${executable_suffix}")
        add_executable("${executable}" "${source}")
        target_link_options("${executable}" PUBLIC "-fopenmp")
        target_link_libraries("${executable}" HELPER_LIB)

        if (ENABLE_PMT)
            target_link_libraries("${executable}" pmt)
        endif()

        install(TARGETS "${executable}" RUNTIME DESTINATION ${PROJECT_SOURCE_DIR}/bin)

        endforeach()
    endforeach()

