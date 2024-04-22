# Almost all CMake files should start with this
# You should always specify a range with the newest
# and oldest tested versions of CMake. This will ensure
# you pick up the best policies.
cmake_minimum_required(VERSION 3.24.0)

# This is your project statement. You should always list languages;
# Listing the version is nice here since it sets lots of useful variables
project(
  EnergyEfficientComputing
  VERSION 1.0
  LANGUAGES C CXX)

# Find packages go here.
add_subdirectory(src)
include_directories(".")

option(ENABLE_CUDA "Compile Cuda programs" OFF)
option(ENABLE_PMT "Compile programs with PMT functionality" OFF)
