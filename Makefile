CXXFLAGS = -std=c++23 -Wall -Wextra -fsanitize=address -ggdb3 -MMD
cube: cube.cpp

clean:
	rm -f -- cube *.[do]

-include *.d
