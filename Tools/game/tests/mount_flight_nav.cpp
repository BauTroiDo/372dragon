// Differential oracle: use the same PathLib parser/point query as the client.
#include "NavMesh.h"
#include <fstream>
#include <iostream>
#include <iomanip>
#include <random>
#include <cassert>
int main(int argc,char** argv) {
    assert(argc==3);
    std::ifstream bundle(argv[1],std::ios::binary),index(argv[2]);
    unsigned id,offset,length;int maps=0,points=0;
    std::cout<<std::setprecision(9);
    while(index>>id>>offset>>length) {
        std::vector<char> bytes(length);bundle.seekg(offset);bundle.read(bytes.data(),length);assert(bundle.good());
        PathLib::NavMesh mesh;assert(mesh.parse(bytes.data(),bytes.size()));++maps;
        auto emit=[&](float x,float z){auto t=mesh.findTri(x,z);
            std::cout<<id<<' '<<x<<' '<<z<<' '<<(t<mesh.tris.size()&&!mesh.tris[t].blocked())<<'\n';++points;};
        std::mt19937 random(id+20260924);
        for(int i=0;i<1000;++i)emit((random()%1000000)/1000000.0f*mesh.nx*mesh.cellSize,(random()%1000000)/1000000.0f*mesh.nz*mesh.cellSize);
        for(size_t i=0;i<mesh.verts.size();i+=std::max<size_t>(1,mesh.verts.size()/200)) {
            const auto& p=mesh.verts[i];if(p.x<0||p.z<0)continue;
            emit(p.x,p.z);emit(p.x+.001f,p.z+.001f);
        }
    }
    std::cerr<<"PASS client oracle "<<maps<<" scenes, "<<points<<" points\n";
}
