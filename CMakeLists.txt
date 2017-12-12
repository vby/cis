cmake_minimum_required(VERSION 2.6)

project(xcmake NONE)

if(WIN32)
	install(PROGRAMS xcmake.bat DESTINATION ${CMAKE_INSTALL_PREFIX})
else()
	install(PROGRAMS xcmake DESTINATION "bin")
endif()

