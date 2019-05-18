TARGET = parser
LEX = flex
YACC = yacc
CXX = g++

.PHONY: all clean

all: $(TARGET)

$(TARGET): lex.yy.cpp y.tab.cpp SymbolTables.cpp SymbolTables.hpp
	$(CXX) y.tab.cpp SymbolTables.cpp -o $(TARGET) -ll -ly -std=c++11 -Wno-deprecated-register

lex.yy.cpp: pj2-scanner.l
	$(LEX) -o lex.yy.cpp pj2-scanner.l

y.tab.cpp: pj2-parser.y
	$(YACC) -d pj2-parser.y -o y.tab.cpp

clean:
	$(RM) $(TARGET) lex.yy.cpp y.tab.*
