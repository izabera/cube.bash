LDFLAGS = -fsanitize=address
CXXFLAGS = -std=c++23 -Wall -Wextra -fsanitize=address -ggdb3 -MMD
LINK.o = $(CXX) $(LDFLAGS) $(TARGET_ARCH)
cube: cube.o

clean:
	rm -f -- cube *.[do]

-include *.d
