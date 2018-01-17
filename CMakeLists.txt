cmake_minimum_required(VERSION 2.6)

project(XCMake NONE)

install(PROGRAMS xcmake DESTINATION bin)

if(WIN32)
	install(PROGRAMS xcmake.bat DESTINATION bin)
endif()

install(FILES XCMake.cmake DESTINATION bin)

