cmake_minimum_required(VERSION 2.6)

project(xcmake NONE)

install(PROGRAMS xcmake DESTINATION "bin")

if(WIN32)
	install(PROGRAMS xcmake.bat DESTINATION "bin")
endif()

