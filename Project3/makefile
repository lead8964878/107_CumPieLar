ifeq ($(shell uname -s), Darwin)
	javaa := ./javaa_mac
else
	javaa := ./javaa
endif

TARGET = pj3-compiler
LEX = flex
YACC = yacc
CXX = g++

.PHONY: all clean

all: $(TARGET)

$(TARGET): lex.yy.cpp y.tab.cpp SymbolTables.cpp SymbolTables.hpp OutputGenerator.cpp OutputGenerator.hpp
	$(CXX) y.tab.cpp SymbolTables.cpp OutputGenerator.cpp -o $(TARGET) -ll -ly -std=c++11 -Wno-deprecated-register

lex.yy.cpp: pj3-scanner.l
	$(LEX) -o lex.yy.cpp pj3-scanner.l

y.tab.cpp: pj3-parser.y
	$(YACC) -d pj3-parser.y -o y.tab.cpp -v

clean:
	$(RM) $(TARGET) lex.yy.cpp y.tab.*

run: $(TARGET)
	 ./$(TARGET) $(file).modula.txt
	 $(javaa) $(file).jasm
	 java $(file)
	 