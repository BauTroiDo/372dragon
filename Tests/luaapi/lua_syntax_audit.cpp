#include "LuaPlus.h"
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
// Use the game's LuaPlus parser, not an incompatible modern system Lua.
// LoadBuffer compiles without running the chunk or any host API.
int main(int argc,char** argv){
    if(argc!=2)return 2;
    auto lua=LuaPlus::LuaState::Create(true);
    if(lua->LoadBuffer("function (",10,"negative-control")==0)return 3;
    lua->SetTop(0);
    std::ifstream paths(argv[1]);if(!paths)return 4;
    std::string path;int count=0,failed=0;
    while(std::getline(paths,path)){
        if(!path.empty()&&path.back()=='\r')path.pop_back();
        std::ifstream file(path,std::ios::binary);++count;
        if(!file){++failed;std::cout<<"UNREADABLE "<<path<<"\n";continue;}
        std::string bytes((std::istreambuf_iterator<char>(file)),{});
        if(lua->LoadBuffer(bytes.data(),bytes.size(),path.c_str())!=0){
            ++failed;std::cout<<"FAIL "<<path<<" "<<LuaPlus::LuaStackObject(lua,-1).GetString()<<"\n";
        }
        lua->SetTop(0);
    }
    LuaPlus::LuaState::Destroy(lua);
    std::cout<<"compiled="<<count<<" failed="<<failed<<" negative_control=rejected\n";
    return count==0||failed?1:0;
}
