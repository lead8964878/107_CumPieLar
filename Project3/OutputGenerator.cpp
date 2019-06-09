#include "OutputGenerator.hpp"

LabelManager lm;

Label::Label(int num)
{
  count = num;
  loop_flag = -1;
}

LabelManager::LabelManager()
{
  labelCount = 0;
}

void LabelManager::pushNLabel(int n)
{
  lStack.push(Label(labelCount));
  labelCount += n;
}

void LabelManager::NLabel(int n)
{
  lStack.top().count += n;
  labelCount += n;
}

void LabelManager::popLabel()
{
  lStack.pop();
}

int LabelManager::takeLabel(int n)
{
  return lStack.top().count + n;
}

int LabelManager::getLable()
{
  return labelCount++;
}

int LabelManager::getFlag()
{
  return lStack.top().loop_flag;
}

void outProgramStart()
{
  out << "class " << filename << endl << "{" << endl;
}

void outProgramEnd()
{
  out << "}" << endl;
}

void outBlockEnd()
{
  out << "\t}" << endl;
}

void outGlobalVar(string id)
{
  out << "\tfield static int " << id << endl;
}

void outLocalVar(int idx)
{
  out << "\t\tistore " << idx << endl;
}

void outConstStr(string str)
{
  out << "\t\tldc \"" << str << "\"" << endl;
}

void outConstInt(int val)
{
  out << "\t\tsipush " << val << endl;
}

void outGetGlobalVar(string id)
{
  out << "\t\tgetstatic int " << filename << "." << id << endl;
}

void outGetLocalVar(int idx)
{
  out << "\t\tiload " << idx << endl;
}

void outSetGlobalVar(string id)
{
  out << "\t\tputstatic int " << filename << "." << id << endl;
}

void outSetLocalVar(int idx)
{
  out << "\t\tistore " << idx << endl;
}

void outOperator(char op)
{
  switch (op) {
    case 'm': out << "\t\tineg" << endl; break;
    case '*': out << "\t\timul" << endl; break;
    case '/': out << "\t\tidiv" << endl; break;
    case '+': out << "\t\tiadd" << endl; break;
    case '-': out << "\t\tisub" << endl; break;
    case '!': out << "\t\tldc 1" << endl << "\t\tixor" << endl; break;
    case '&': out << "\t\tiand" << endl; break;
    case '|': out << "\t\tior" << endl; break;
    case '%': out << "\t\tirem" << endl; break;
  }
}

void outCondOp(int op){
  out << "\t\tisub" << endl;
  int lb1 = lm.getLable();
  int lb2 = lm.getLable();
  switch (op) {
    case IFLT: out << "\t\tiflt"; break;
    case IFGT: out << "\t\tifgt"; break;
    case IFLE: out << "\t\tifle"; break;
    case IFGE: out << "\t\tifge"; break;
    case IFEQ: out << "\t\tifeq"; break;
    case IFNE: out << "\t\tifne"; break;
  }
  out << " L" << lb1 << endl;
  out << "\t\ticonst_0" << endl;
  out << "\t\tgoto L" << lb2 << endl;
  out << "\t\tnop" << endl << "L" << lb1 << ":" << endl;
  out << "\t\ticonst_1" << endl;
  out << "\t\tnop" << endl << "L" << lb2 << ":" << endl;
}

void outMainStart()
{
  out << "\tmethod public static void main(java.lang.String[])" << endl;
  out << "\tmax_stack 15" << endl;
  out << "\tmax_locals 15" << endl << "\t{" << endl;
}

void outProcStart(idInfo info)
{
  out << "\tmethod public static ";
  out << ((info.type == void_Type)? "void" : "int");
  out << " " + info.id + "(";
  for (int i = 0; i < info.value.proc_Val.size(); i++) {
    if (i != 0) out << ", ";
    out << "int";
  }
  out << ")" << endl;
  out << "\tmax_stack 15" << endl;
  out << "\tmax_locals 15" << endl << "\t{" << endl;
}

void outVoidProcEnd()
{
  out << "\t\treturn" << endl << "\t}" << endl;
}

void outPrintStart()
{
  out << "\t\tgetstatic java.io.PrintStream java.lang.System.out" << endl;
}

void outPrintStr()
{
  out << "\t\tinvokevirtual void java.io.PrintStream.print(java.lang.String)" << endl;
}

void outPrintInt()
{
  out << "\t\tinvokevirtual void java.io.PrintStream.print(int)" << endl;
}

void outPrintlnStr()
{
  out << "\t\tinvokevirtual void java.io.PrintStream.println(java.lang.String)" << endl;
}

void outPrintlnInt()
{
  out << "\t\tinvokevirtual void java.io.PrintStream.println(int)" << endl;
}

void outIReturn()
{
  out << "\t\tireturn" << endl;
}

void outReturn()
{
  out << "\t\treturn" << endl;
}

void outCallProc(idInfo info)
{
  out << "\t\tinvokestatic ";
  out << ((info.type == void_Type)? "void" : "int");
  out << " " + filename + "." + info.id + "(";
  for (int i = 0; i < info.value.proc_Val.size(); ++i) {
    if (i != 0) out << ", ";
    out << "int";
  }
  out << ")" << endl;
}

void outIfStart()
{
  lm.pushNLabel(2);
  out << "\t\tifeq L" << lm.takeLabel(0) << endl;
}

void outElse()
{
  out << "\t\tgoto L" << lm.takeLabel(1) << endl;
  out << "\t\tnop" << endl << "L" << lm.takeLabel(0) << ":" << endl;
}

void outIfEnd()
{
  out << "\t\tnop" << endl << "L" << lm.takeLabel(0) << ":" << endl;
  lm.popLabel();
}

void outIfElseEnd()
{
  out << "\t\tnop" << endl << "L" << lm.takeLabel(1) << ":" << endl;
  lm.popLabel();
}

void outWhileStart()
{
  lm.pushNLabel(1);
  out << "\t\tnop" << endl << "L" << lm.takeLabel(0) << ":" << endl;
}

void outWhileCond()
{
  lm.NLabel(1);
  out << "\t\tifeq L" << lm.takeLabel(3 + lm.getFlag()) << endl;
}

void outWhileEnd()
{
  out << "\t\tgoto L" << lm.takeLabel(lm.getFlag()) << endl;
  out << "\t\tnop" << endl << "L" << lm.takeLabel(3 + lm.getFlag()) << ":" << endl;
  lm.popLabel();
}
