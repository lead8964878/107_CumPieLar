TARGET = parser
LEX = flex
CXX = g++

.PHONY: all clean

all: $(TARGET)

$(TARGET): lex.yy.cpp y.tab.cpp SymbolTables.cpp SymbolTables.hpp
	$(CXX) y.tab.cpp symbols.cpp -o $(TARGET) -ll -ly -std=c++11 -Wno-deprecated-register

lex.yy.cpp: pj2-scanner.l
	$(LEX) -o lex.yy.cpp pj2-scanner.l

y.tab.cpp: parser.y
	yacc -d parser.y -o y.tab.cpp

clean:
	$(RM) $(TARGET) lex.yy.cpp y.tab.*
