cmake_minimum_required(VERSION 3.0)

project(bc7enc VERSION 1.0.0 LANGUAGES CXX)

set(ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(INCLUDE_DIR "${ROOT_DIR}/include")
set(SOURCE_DIR "${ROOT_DIR}/src")

option(BUILD_X64 "build 64-bit" TRUE)
option(SUPPORT_BC7E "support BC7E (requires ispc)" FALSE)

message("Initial BUILD_X64=${BUILD_X64}")
message("Initial CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
message("Initial SUPPORT_BC7E=${SUPPORT_BC7E}")

if( NOT CMAKE_BUILD_TYPE )
  set( CMAKE_BUILD_TYPE Release )
endif( NOT CMAKE_BUILD_TYPE )

message( ${PROJECT_NAME} " build type: " ${CMAKE_BUILD_TYPE} )

if (BUILD_X64)
	message("Building 64-bit")
else()
	message("Building 32-bit")
endif(BUILD_X64)

if (NOT MSVC)
	set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -fopenmp")
	set(CMAKE_C_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -fopenmp")

	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -fopenmp")
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -fopenmp")
else()
	set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /openmp /W4")
	set(CMAKE_C_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /openmp /W4")

	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /openmp /W4")
	set(CMAKE_C_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /openmp /W4")
endif()

if (SUPPORT_BC7E)
	if (NOT MSVC)
		add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/bc7e.o ${CMAKE_SOURCE_DIR}/bc7e_avx.o ${CMAKE_SOURCE_DIR}/bc7e_sse2.o ${CMAKE_SOURCE_DIR}/bc7e_sse4.o ${CMAKE_SOURCE_DIR}/bc7e_avx2.o
			COMMAND ispc -g -O2 ${CMAKE_SOURCE_DIR}/bc7e.ispc -o ${CMAKE_SOURCE_DIR}/bc7e.o -h ${CMAKE_SOURCE_DIR}/bc7e_ispc.h --target=sse2,sse4,avx,avx2 --opt=fast-math --opt=disable-assertions
										 	DEPENDS bc7e.ispc)
	else()
		add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/bc7e.obj ${CMAKE_SOURCE_DIR}/bc7e_avx.obj ${CMAKE_SOURCE_DIR}/bc7e_sse2.obj ${CMAKE_SOURCE_DIR}/bc7e_sse4.obj ${CMAKE_SOURCE_DIR}/bc7e_avx2.obj
			COMMAND ispc -g -O2 ${CMAKE_SOURCE_DIR}/bc7e.ispc -o ${CMAKE_SOURCE_DIR}/bc7e.obj -h ${CMAKE_SOURCE_DIR}/bc7e_ispc.h --target=sse2,sse4,avx,avx2 --opt=fast-math --opt=disable-assertions
										 	DEPENDS bc7e.ispc)
	endif()
endif()

# -fno-strict-aliasing shouldn't be necessary, it's here because that is what MSVC uses by default and that's what I've tested with the most.
if (NOT MSVC)
	set(GCC_COMPILE_FLAGS "-fno-strict-aliasing -Wall -Wextra")
	if (NOT BUILD_X64)
		set(GCC_COMPILE_FLAGS "${GCC_COMPILE_FLAGS} -m32")
	endif()
endif()	

set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} ${GCC_COMPILE_FLAGS}")
set(CMAKE_C_FLAGS_RELEASE  "${CMAKE_C_FLAGS_RELEASE} ${GCC_COMPILE_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${GCC_COMPILE_FLAGS} -D_DEBUG")

if (SUPPORT_BC7E)
	set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${GCC_COMPILE_FLAGS} -DSUPPORT_BC7E=1")
else()
	set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${GCC_COMPILE_FLAGS}")
endif()

set(CMAKE_CXX_FLAGS_RELEASE  "${CMAKE_CXX_FLAGS_RELEASE} ${GCC_COMPILE_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${GCC_COMPILE_FLAGS} -D_DEBUG")

set (HEADER_FILES
	${INCLUDE_DIR}/bc7enc/bc7decomp.h
	${INCLUDE_DIR}/bc7enc/bc7enc.h
	${INCLUDE_DIR}/bc7enc/dds_defs.h
	${INCLUDE_DIR}/bc7enc/ert.h
	${INCLUDE_DIR}/bc7enc/lodepng.h
	${INCLUDE_DIR}/bc7enc/miniz.h
	${INCLUDE_DIR}/bc7enc/rdo_bc_encoder.h
	${INCLUDE_DIR}/bc7enc/rgbcx.h
	${INCLUDE_DIR}/bc7enc/rgbcx_table4.h
	${INCLUDE_DIR}/bc7enc/rgbcx_table4_small.h
	${INCLUDE_DIR}/bc7enc/utils.h)

set (SOURCE_FILES
	${SOURCE_DIR}/bc7enc.cpp
	${SOURCE_DIR}/bc7decomp.cpp
	${SOURCE_DIR}/bc7decomp_ref.cpp
	${SOURCE_DIR}/lodepng.cpp
	${SOURCE_DIR}/rgbcx.cpp
	${SOURCE_DIR}/utils.cpp
	${SOURCE_DIR}/ert.cpp
	${SOURCE_DIR}/rdo_bc_encoder.cpp
	)

if (NOT SUPPORT_BC7E)
		add_library(${PROJECT_NAME} STATIC ${HEADER_FILES} ${SOURCE_FILES})
else()
	if (NOT MSVC)
		add_library(${PROJECT_NAME} STATIC ${HEADER_FILES} ${SOURCE_FILES} ${CMAKE_SOURCE_DIR}/bc7e.o ${CMAKE_SOURCE_DIR}/bc7e_avx.o ${CMAKE_SOURCE_DIR}/bc7e_avx2.o ${CMAKE_SOURCE_DIR}/bc7e_sse2.o ${CMAKE_SOURCE_DIR}/bc7e_sse4.o)
	else()
		add_library(${PROJECT_NAME} STATIC ${HEADER_FILES} ${SOURCE_FILES} ${CMAKE_SOURCE_DIR}/bc7e.obj ${CMAKE_SOURCE_DIR}/bc7e_avx.obj ${CMAKE_SOURCE_DIR}/bc7e_avx2.obj ${CMAKE_SOURCE_DIR}/bc7e_sse2.obj ${CMAKE_SOURCE_DIR}/bc7e_sse4.obj)
	endif()
endif()

if (NOT MSVC)
	target_link_libraries(${PROJECT_NAME} m)
endif()

target_include_directories(
		"${PROJECT_NAME}" SYSTEM
		PUBLIC "$<BUILD_INTERFACE:${INCLUDE_DIR}>"
		"$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
		PRIVATE "$<BUILD_INTERFACE:${INCLUDE_DIR}>"
		"$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")

add_executable(${PROJECT_NAME}_app src/test.cpp)
target_link_libraries(${PROJECT_NAME}_app ${PROJECT_NAME})

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

install(TARGETS "${PROJECT_NAME}" EXPORT "${PROJECT_NAME}-targets")

install(
		EXPORT "${PROJECT_NAME}-targets"
		NAMESPACE "bc7enc::"
		DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

configure_file("${ROOT_DIR}/cmake/config.cmake.in"
		"${PROJECT_NAME}Config.cmake" @ONLY)

write_basic_package_version_file(
		"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
		COMPATIBILITY SameMajorVersion)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
		"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
		DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

install(DIRECTORY "${INCLUDE_DIR}/bc7enc"
		DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")