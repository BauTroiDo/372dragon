#include "CysFlightGrid.h"
#include "CysMountFlightPacket.h"
#include <cassert>
#include <fstream>
#include <iostream>
#include <iterator>
#include <limits>
int main(int argc,char** argv) {
    CysFlightGrid grid;float y=0;
    uint32_t n=6;float values[]={10,20,30,40,50,60};
    std::vector<char> bytes(28);memcpy(bytes.data(),&n,4);memcpy(bytes.data()+4,values,24);
    assert(grid.Load(bytes.data(),bytes.size(),2,1));
    assert(grid.Sample(.5f,.5f,y)&&std::fabs(y-30)<.0001f);
    assert(grid.Sample(2,1,y)&&y==60);
    for(float x:{0.0f,.5f,1.0f,2.0f}) for(float z:{0.0f,.5f,1.0f}) assert(grid.FlatSample(x,z,y)&&y==60);
    assert(!grid.FlatSample(-.1f,0,y)&&!grid.FlatSample(2.01f,0,y));
    assert(!grid.FlatSample(std::numeric_limits<float>::infinity(),0,y));
    assert(!grid.Sample(-.1f,0,y)&&!grid.Sample(2.01f,0,y));
    assert(!grid.Sample(std::numeric_limits<float>::quiet_NaN(),0,y));
    bytes.insert(bytes.begin()+4,16,0);assert(grid.Load(bytes.data(),bytes.size(),2,1));
    assert(grid.Sample(.5f,.5f,y)&&std::fabs(y-30)<.0001f);
    assert(!grid.Load(bytes.data(),bytes.size()-1,2,1));assert(!grid.Sample(0,0,y));
    assert(!grid.FlatSample(0,0,y));
    assert(grid.Load(bytes.data(),bytes.size(),1,2)); // same count accepted with declared dimensions
    float nan=std::numeric_limits<float>::quiet_NaN();memcpy(bytes.data()+20,&nan,4);
    assert(!grid.Load(bytes.data(),bytes.size(),2,1));
    pg::CGFlyOperation p;p.object=0x12345678;p.operation=1;pg::Writer w;p.write(w);
    assert(p.packetId()==2242&&p.wireSize()==5);
    const uint8_t native[]={0x78,0x56,0x34,0x12,1};assert(w.size()==5&&!memcmp(w.buffer().data(),native,5));
    for(int i=0;i<5;++i){pg::Reader r(native,i);assert(!p.read(r));}
    pg::Reader r(native,5);assert(p.read(r)&&p.operation==1&&p.object==0x12345678);
    for(int i=1;i+2<argc;i+=3){std::ifstream file(argv[i],std::ios::binary);std::vector<char> b((std::istreambuf_iterator<char>(file)),{});
        int x=std::stoi(argv[i+1]),z=std::stoi(argv[i+2]);assert(grid.Load(b.data(),b.size(),x,z));
        assert(grid.Sample(x/2.0f,z/2.0f,y));std::cout<<"PASS canonical grid "<<argv[i]<<" centre="<<y<<'\n';}
    std::cout<<"PASS grid boundaries, both headers, truncation/NaN and native packet codec\n";
}
