# CYS component: Opcode 1.3 (Pierre Terdiman) - static library.
# Used by WXCore (WXOpcode.h -> <Opcode.h>) for ray/mesh collision (terrain picking, collision models).
# Old project: ThirdParty/Opcode/Opcode.dsp (DLL, /QIfist). 0.85 linked it statically (Opcode.h: ICE_NO_DLL),
# so OPCODE_API is empty and no export macro is needed.
# x64 port: Ice/IceFPU.h + Ice/IceMemoryMacros.h inline asm -> C++ on _WIN64; tree nodes that store pointers
# (OPC_AABBTree.h mPos/mNeg, OPC_OptimizedTree.h mData/mPosData/mNegData) widened udword -> size_t.
set(_cys_opc "${CYS_TP}/Opcode")
add_library(cys_opcode STATIC
    "${_cys_opc}/Opcode.cpp"
    "${_cys_opc}/StdAfx.cpp"
    "${_cys_opc}/OPC_AABBCollider.cpp"
    "${_cys_opc}/OPC_AABBTree.cpp"
    "${_cys_opc}/OPC_BaseModel.cpp"
    "${_cys_opc}/OPC_BoxPruning.cpp"
    "${_cys_opc}/OPC_Collider.cpp"
    "${_cys_opc}/OPC_Common.cpp"
    "${_cys_opc}/OPC_HybridModel.cpp"
    "${_cys_opc}/OPC_LSSCollider.cpp"
    "${_cys_opc}/OPC_MeshInterface.cpp"
    "${_cys_opc}/OPC_Model.cpp"
    "${_cys_opc}/OPC_OBBCollider.cpp"
    "${_cys_opc}/OPC_OptimizedTree.cpp"
    "${_cys_opc}/OPC_Picking.cpp"
    "${_cys_opc}/OPC_PlanesCollider.cpp"
    "${_cys_opc}/OPC_RayCollider.cpp"
    "${_cys_opc}/OPC_SphereCollider.cpp"
    "${_cys_opc}/OPC_SweepAndPrune.cpp"
    "${_cys_opc}/OPC_TreeBuilders.cpp"
    "${_cys_opc}/OPC_TreeCollider.cpp"
    "${_cys_opc}/OPC_VolumeCollider.cpp"
    "${_cys_opc}/Ice/IceAABB.cpp"
    "${_cys_opc}/Ice/IceContainer.cpp"
    "${_cys_opc}/Ice/IceHPoint.cpp"
    "${_cys_opc}/Ice/IceIndexedTriangle.cpp"
    "${_cys_opc}/Ice/IceMatrix3x3.cpp"
    "${_cys_opc}/Ice/IceMatrix4x4.cpp"
    "${_cys_opc}/Ice/IceOBB.cpp"
    "${_cys_opc}/Ice/IcePlane.cpp"
    "${_cys_opc}/Ice/IcePoint.cpp"
    "${_cys_opc}/Ice/IceRandom.cpp"
    "${_cys_opc}/Ice/IceRay.cpp"
    "${_cys_opc}/Ice/IceRevisitedRadix.cpp"
    "${_cys_opc}/Ice/IceSegment.cpp"
    "${_cys_opc}/Ice/IceTriangle.cpp"
    "${_cys_opc}/Ice/IceUtils.cpp")
target_include_directories(cys_opcode PUBLIC "${_cys_opc}")
target_compile_definitions(cys_opcode PRIVATE OPCODE_EXPORTS)
if(MSVC)
    # Surface pointer-truncation warnings (C4311/C4312 level 1, C4302 level 2) - this code stores pointers in ints.
    target_compile_options(cys_opcode PRIVATE /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_opcode PROPERTIES OUTPUT_NAME Opcode FOLDER ThirdParty)
