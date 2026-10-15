# Compiler
CC=g++
CFLAGS=-c -Wall -fPIC -std=c++17 -DLEXY_HAS_UNICODE_DATABASE

# Directories
SRCDIR=src
INCDIR=include
OBJDIR=obj
LIBDIR=lib
DEPDIR=$(OBJDIR)/deps
TINYXML2DIR=3rdparty/tinyxml2
WILDCARDS_DIR=3rdparty/wildcards
LEXY_DIR=3rdparty/lexy

# Libraries
LIBS=-pthread

# Sources
SRCS=$(wildcard $(SRCDIR)/*.cpp $(SRCDIR)/*/*.cpp)
OBJS=$(patsubst $(SRCDIR)/%.cpp,$(OBJDIR)/%.o,$(SRCS))

# Dependencies
DEPS=$(OBJS:%.o=$(DEPDIR)/%.d)



# TinyXML2 sources
TINYXML2_SRCS=$(wildcard $(TINYXML2DIR)/*.cpp)
TINYXML2_OBJS=$(patsubst $(TINYXML2DIR)/%.cpp,$(OBJDIR)/%.o,$(TINYXML2_SRCS))

# Wildcards sources
WILDCARDS_SRCS=$(wildcard $(WILDCARDS_DIR)/*.cpp)
WILDCARDS_OBJS=$(patsubst $(WILDCARDS_DIR)/%.cpp,$(OBJDIR)/%.o,$(WILDCARDS_SRCS))

# lexy sources
LEXY_SRCS=$(wildcard $(LEXY_DIR)/src/*.cpp)
LEXY_OBJS=$(patsubst $(LEXY_DIR)/src/%.cpp,$(OBJDIR)/%.o,$(LEXY_SRCS))

# Executable
EXECUTABLE=$(LIBDIR)/libbehaviortree_cpp.a

# Include directories
INCLUDES=-I$(INCDIR) -I$(TINYXML2DIR) -I$(LEXY_DIR)/include -I3rdparty

# Link tinyxml2 and wildcards lexy static library
LDFLAGS=-L$(LIBDIR) -ltinyxml2 -lwildcards -llexy

# Make rules
all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJS) $(TINYXML2_OBJS) $(WILDCARDS_OBJS) $(LEXY_OBJS) | $(LIBDIR)
	ar rcs $@ $^

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp | $(OBJDIR) $(DEPDIR)
	$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -MF $(DEPDIR)/$*.d -o $@ $<

$(OBJDIR)/%.o: $(TINYXML2DIR)/%.cpp | $(OBJDIR) $(DEPDIR)
	$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -MF $(DEPDIR)/$*.d -o $@ $<

$(OBJDIR)/%.o: $(WILDCARDS_DIR)/%.cpp | $(OBJDIR) $(DEPDIR)
	$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -MF $(DEPDIR)/$*.d -o $@ $<

$(OBJDIR)/%.o: $(LEXY_DIR)/src/%.cpp | $(OBJDIR) $(DEPDIR)
	$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -MF $(DEPDIR)/$*.d -o $@ $<

$(LIBDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(DEPDIR):
	mkdir -p $(DEPDIR)
clean:
	rm -rf $(OBJDIR) $(LIBDIR) 