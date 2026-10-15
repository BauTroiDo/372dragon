# -*- coding: utf-8 -*-
"""CY-Source data validators (Docs/05-QUY-TRINH-TAI-SAN_vi.md muc 7).

One module per check; every module works on a data root laid out like client_GL\\Data and never writes
into it:
  v01_mesh      V01 mesh_parse      sequential walk, version, index/vertex ranges, padding
  v02_skeleton  V02 skeleton_parse  [Serializer_v1.10] + chunk 0x4120, bone refs, <= 74 bones per submesh (warn)
  v03_obj       V03 obj_integrity   every reference of an all.obj object resolves inside the data root
  v04_material  V04 material_refs   parent chain ends in MaterialTemplates.zip, aliases declared, textures exist
  v05_dds       V05 dds_check       header, fourCC, mipmaps, size, power of two
  v06_effect    V06 effect_strict   strict parse of all.effect / all.particle blocks + their references
  v13_gbk       V13 gbk_roundtrip   all.* bytes outside the recorded edits identical to the base file
  run           command line runner (touched-set JSON -> validate.json / validate.txt)

Severity: 'error' blocks a batch, 'warn' is recorded in the batch report, 'info' is statistics.
"""
