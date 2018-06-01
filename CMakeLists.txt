cmake_minimum_required(VERSION 2.6)

project(cis NONE)

install(PROGRAMS cis DESTINATION bin)

if(WIN32)
	install(PROGRAMS cis.bat DESTINATION bin)
endif()

