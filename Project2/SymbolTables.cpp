#include "SymbolTables.hpp"

//Symbol Table Func Definition
SymbolTable::SymbolTable()
{

}

int SymbolTable::insert(string id, int type, int prefix, idValue value, bool valueInitialed)
{
  if (symbolMap.find(id) != symbolMap.end())
    return -1;
  else {
    symbolList.push_back(id);
    symbolMap[id].id = id;
    symbolMap[id].type = type;
    symbolMap[id].prefix = prefix;
    symbolMap[id].value = value;
    symbolMap[id].valueInitialed = valueInitialed;
    return 1;
  }
}

void SymbolTable::dump()
{
  cout << "=id=\t\t=prefix=\t=type=\t\t=value=" << endl;
  string s;
  for (int i = 0; i < symbolList.size(); i++)
  {
    idInfo info = symbolMap[symbolList[i]];
    s = info.id + "\t\t";
    switch (info.prefix) {
      case array_Prefix: s += "array\t\t"; break;
      case const_Prefix: s += "const\t\t"; break;
      case variable_Prefix: s += "var\t\t"; break;
      case procedure_Prefix: s += "proc\t\t"; break;
      case module_Prefix: s += "module\t\t"; break;
    }
    switch (info.type) {
      case string_Type: s += "string\t\t"; break;
      case int_Type: s += "int\t\t"; break;
      case real_Type: s += "float\t\t"; break;
      case bool_Type: s += "bool\t\t"; break;
      case void_Type: s += "void\t\t"; break;
    }
    if (info.valueInitialed) {
      switch (info.type) {
        case int_Type: s += to_string(info.value.i_Val); break;
        case real_Type: s += to_string(info.value.r_Val); break;
        case bool_Type: s += (info.value.b_Val)? "true" : "false"; break;
        case string_Type: s += info.value.s_Val; break;
      }
    }
    if (info.prefix == procedure_Prefix) {
      s += "{ ";
      for (int i = 0; i < info.value.proc_Val.size(); ++i) {
        switch (info.value.proc_Val[i].type) {
          case string_Type: s += "string "; break;
          case int_Type: s += "int "; break;
          case real_Type: s += "real "; break;
          case bool_Type: s += "bool "; break;
        }
      }
      s += "}";
    }
    if (info.type == array_Type) {
	  switch (info.value.array_Val[0].type) {
        case int_Type: s += "int\t\t"; break;
        case real_Type: s += "real\t\t"; break;
        case bool_Type: s += "bool\t\t"; break;
        case string_Type: s += "str\t\t"; break;
      }
      s += "{ ";
      s += to_string(info.value.arrayStart_Index)+" , "+ to_string(info.value.arrayEnd_Index) + " }";
    }
    cout << s << endl;
  }
  cout << endl;
}

bool SymbolTable::isExist(string id)
{
  return symbolMap.find(id) != symbolMap.end();
}

idInfo *SymbolTable::lookup(string id)
{
  return new idInfo(symbolMap[id]);
}

void SymbolTable::setFuncType(int type)
{
  symbolMap[symbolList[symbolList.size() - 1]].type = type;
}

void SymbolTable::addFuncArg(string id, idInfo info)
{
  symbolMap[symbolList[symbolList.size() - 1]].value.proc_Val.push_back(info);
}

//Symbol Table List Func Definition
SymbolTableList::SymbolTableList()
{
  top = -1;
  push();
}

void SymbolTableList::push()
{
  symboltableList.push_back(SymbolTable());
  top++;
}

bool SymbolTableList::pop()
{
  if (symboltableList.size() <= 0)
  return false;

  symboltableList.pop_back();
  top--;
  return true;
}

int SymbolTableList::insert(string id, idInfo info)
{
  return symboltableList[top].insert(id, info.type, info.prefix, info.value, info.valueInitialed);
}

int SymbolTableList::insert(string id, int type, int start,int end)
{
  idValue val;
  val.array_Val.resize(end - start + 1);
  for(int i = 0; i < end - start + 1; i++){
    val.arrayStart_Index = start;
    val.arrayEnd_Index = end;
    val.array_Val[i].type = type;
    val.array_Val[i].prefix = array_Prefix;
  }
  return symboltableList[top].insert(id, array_Type, array_Prefix, val, false);
}

idInfo *SymbolTableList::lookup(string id)
{
  for (int i = top; i >= 0; i--) {
    if (symboltableList[i].isExist(id)) 
    return symboltableList[i].lookup(id);
  }
  return NULL;
}

void SymbolTableList::dump()
{
  cout << "<--------- Dump Start --------->" << endl << endl;
  for (int i = top; i >= 0; --i) {
    cout << "Frame index: " << i << endl;
    symboltableList[i].dump();
  }
  cout << "<---------- Dump End ---------->" << endl;
}
void SymbolTableList::setFuncType(int type)
{
  symboltableList[top - 1].setFuncType(type);
}

void SymbolTableList::addFuncArg(string id, idInfo info)
{
  symboltableList[top - 1].addFuncArg(id, info);
}


//Extra Func Definition
bool isConst(idInfo info)
{
  if (info.prefix == const_Prefix) 
  return true;

  return false;
}

idInfo *setConst_i(int val)
{
  idInfo* info = new idInfo();
  info->type = int_Type;
  info->value.i_Val = val;
  info->prefix = const_Prefix;
  return info;
}

idInfo *setConst_r(double val)
{
  idInfo* info = new idInfo();
  info->type = real_Type;
  info->value.r_Val = val;
  info->prefix = const_Prefix;
  return info;
}

idInfo *setConst_b(bool val)
{
  idInfo* info = new idInfo();
  info->type = bool_Type;
  info->value.b_Val = val;
  info->prefix = const_Prefix;
  return info;
}

idInfo *setConst_s(string *val)
{
  idInfo* info = new idInfo();
  info->type = string_Type;
  info->value.s_Val = *val;
  info->prefix = const_Prefix;
  return info;
}
