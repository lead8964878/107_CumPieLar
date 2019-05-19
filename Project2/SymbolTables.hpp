#include <iostream>
#include <map>
#include <vector>
#include <string>

using namespace std;

enum idPrefix {
  array_Prefix,
  const_Prefix,
  variable_Prefix,
  module_Prefix,
  procedure_Prefix
};

enum type{
  string_Type,
  int_Type,
  real_Type,
  bool_Type,
  array_Type,
  void_Type
};

struct idValue;
struct idInfo;

struct idValue {
  string s_Val = "";
  int i_Val = 0;
  double r_Val = 0;
  bool b_Val = false;
  vector<idInfo> array_Val;
  int arrayStart_Index;
  int arrayEnd_Index;
  vector<idInfo> proc_Val;
};

struct idInfo {
  string id = "";
  int type = int_Type;
  int prefix = variable_Prefix;
  idValue value;
  bool valueInitialed = false;
};

class SymbolTable {
  private:
    vector<string> symbolList;
    map<string, idInfo> symbolMap;
    int index; 
  public:
    SymbolTable();
    int insert(string id, int type, int flag, idValue value, bool valueInitialed);
    void dump();
    bool isExist(string id);
    idInfo *lookup(string id);
    void setFuncType(int type);
    void addFuncArg(string id, idInfo info);
};

class SymbolTableList {
  private:
    vector<SymbolTable> symboltableList;
    int top;
  public:
    SymbolTableList();
    void push();
    bool pop();
    int insert(string id, idInfo info);
    int insert(string id, int type, int start,int end);
    idInfo *lookup(string id);
    void dump();
    void setFuncType(int type);
    void addFuncArg(string id, idInfo info);
};

bool isConst(idInfo info);
idInfo *setConst_s(string *val);
idInfo *setConst_i(int val);
idInfo *setConst_r(double val);
idInfo *setConst_b(bool val);
