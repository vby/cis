cmake_minimum_required(VERSION 2.6)

project(xcm NONE)

install(PROGRAMS xcm DESTINATION bin)

if(WIN32)
	install(PROGRAMS xcm.bat DESTINATION bin)
endif()

install(FILES xcm.cmake DESTINATION cmake)

