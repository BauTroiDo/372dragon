#pragma once
namespace pg {class Packet;class GCDetailAttrib;}
namespace CysWuhunNet {
void RegisterHost();
bool Dispatch(const pg::Packet&);
void Detail(const pg::GCDetailAttrib&);
int PreviewModel();
}
