cmake_minimum_required(VERSION 2.6)

project(xcmake)

IF (WIN32)
	install(PROGRAMS xcmake.bat DESTINATION ${CMAKE_INSTALL_PREFIX})
ELSE ()
	install(PROGRAMS xcmake DESTINATION "bin")
ENDIF ()

