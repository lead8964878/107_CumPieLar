#pragma once

#include <iostream>
#include <fstream>
#include <stack>
#include "SymbolTables.hpp"

using namespace std;

extern string filename;
extern ofstream out;

enum condition{
  IFLT,
  IFGT,
  IFLE,
  IFGE,
  IFEQ,
  IFNE
};

struct Label {
  int count;
  int loop_flag;
  Label(int num);
};

class LabelManager{
  private:
    int labelCount;
  public:
    stack<Label> lStack;
    LabelManager();
    void pushNLabel(int n);
    void NLabel(int n);
    void popLabel();
    int takeLabel(int n);
    int getLable();
    int getFlag();
};

void outProgramStart();
void outProgramEnd();

void outBlockEnd();

void outGlobalVar(string id);
void outLocalVar(int idx);

void outConstStr(string str);
void outConstInt(int val);

void outGetGlobalVar(string id);
void outGetLocalVar(int idx);
void outSetGlobalVar(string id);
void outSetLocalVar(int idx);

void outOperator(char op);
void outCondOp(int op);

void outMainStart();
void outProcStart(idInfo info);
void outVoidFuncEnd();

void outPrintStart();
void outPrintStr();
void outPrintInt();
void outPrintlnStr();
void outPrintlnInt();

void outIReturn();
void outReturn();

void outCallFunc(idInfo info);

void outIfStart();
void outElse();
void outIfEnd();
void outIfElseEnd();

void outWhileStart();
void outWhileCond();
void outWhileEnd();
