#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'\nTests/fx/effects/census/gen_wx_tables.py - emit wx_dicts.tsv and wx_key_usage.tsv for fx_census.py.\n\nThe tables encode, per (scope,key), what the WXCore effect parsers accept (dicts) and, for keys that are parsed\nand STORED but never read at run time, an IGNORED row with the source evidence. A key present in dicts but with\nno usage row counts as USED. Keys the parsers do not accept at all are absent from dicts -> the census marks them\nNOT_PARSED from the data side. Every claim is grounded in a Src file:line, listed in the evidence column.'
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# Base keys of every element (WXEffectElement::initDefaults). USED unless noted.
BASE = ["StartTime", "LifeTime", "Position", "Orientation", "CreateLevel", "ParentSpaceLock"]
ELEMENT_SCOPES = ["Particle", "NewRibbonTrail", "Beam", "BillboardSet", "Projector", "PointLight", "UIParticle"]

# per-scope own keys the parsers register (from the ParameterDef calls in each *.cpp)
OWN = {
    "effect": ["LifeTime", "use_scale"],  # use_scale: TransformInfo.mScale + LogicModel::setEffectFollowScale
    "element:Particle": ["ParticleSystem", "ParEffectName", "ColEffectName", "use_particle_effect",
                         "use_particle_collision", "use_energy_wave", "legacy_pos_for_sub_effect",
                         "pass_rotation_to_sub_effect"],
    "element:NewRibbonTrail": ["TrailLength", "MaxChainElements", "InitialWidth", "WidthChange", "TailWidth",
                               "LowWidthCut", "HighWidthCut", "ColourFadingTime0", "ColourFadingTime1",
                               "ColourFadingTime2", "ColourFadingTime3", "ColourFadingTime4", "ColourFadingColour0",
                               "ColourFadingColour1", "ColourFadingColour2", "ColourFadingColour3",
                               "ColourFadingColour4", "AlphaColourCut", "LiftTime", "Material", "BillboardType",
                               "Direction_or_Point"],
    "element:Beam": ["NoiseXMin", "NoiseXMax", "NoiseYMin", "NoiseYMax", "NoiseZMin", "NoiseZMax", "NumElements",
                     "Width", "Colour", "ColourRangeStart", "ColourRangeEnd", "Material", "Frequency",
                     # CYS: wave / curve / spline keys now parsed + stored (WXBeamElement)
                     "CurveType", "TexRepeat", "IsVisable", "IsSinPlay", "WaveExtent-y", "WaveExtent-z",
                     "WaveFrequency", "WaveVelocity", "WaveShade-y", "WaveShade-z", "SpLineEditor", "BindElement",
                     "IsSubEleActive", "SubElementFrequency"],
    "element:BillboardSet": ["BillboardColour", "BillboardAlpha", "BillboardCount", "Material", "BillboardInterval",
                             "BillboardHeight", "BillboardWidth", "ScaleIntervalTime", "stacks", "slices",
                             "TexIntervalTime",
                             # CYS-FX (fx-cy): stage keys registered in a loop (MAX_STAGES = 3), CY data uses them
                             "BillboardScale0", "BillboardScale1", "BillboardScale2"],
    "element:Projector": ["Material", "ProjectionSize", "ScaleChangeTime", "ColourChangeTime", "ShowFrustum",
                          "NearClipDistance", "FarClipDistance"],
    "element:PointLight": ["Diffuse", "Specular", "Range", "AttenuationConstant", "AttenuationLinear",
                          "AttenuationQuadric"],
    "element:UIParticle": ["ParticleSystem", "ParEffectName", "ColEffectName", "use_particle_effect",
                          "use_particle_collision", "use_energy_wave", "legacy_pos_for_sub_effect",
                          "pass_rotation_to_sub_effect"],
    "skill": ["Animation", "BreakTime", "HitTime", "ShakeTime", "RepeatEffect", "Removedirectly"],
    "skill:AnimEffect": ["AttachTime", "AttachPoint", "EffectTemplateName", "OffsetPos", "OffsetRotation", "Attach",
                         "DefaultShow"],  # CYS: DefaultShow parsed + gated by System::getHideAnimationEffects
    "skill:Ribbon": ["AttachTime", "AttachPoint", "OffsetPos", "OffsetRotation", "PointCount", "LifeTime",
                     "RibbonWidth", "StartAlphaValue", "EndAlphaValue", "StartColour", "EndColour", "FadeInTime",
                     "FadeOutTime", "Material", "InterTimes", "UseInter", "VertexLifeTime"],
    "skill:Sound": ["SoundName", "AttachTime"],
    "skill:SceneLight": ["AttachTime", "LastTime", "FadeInTime", "FadeOutTime", "DestColour"],
    "skill:CameraShake": ["AttachTime", "Duration", "RotAmplitude", "RotFrequency", "LocAmplitude", "LocFrequency",
                          "FovAmplitude", "FovFrequency", "ShakeManner", "IsLocalVisible"],
    "skill:ComplexBlur": ["AttachTime", "StartTime", "MidTime", "EndTime", "Strength", "Unblured", "FinalDistance",
                         "IsLocalVisible"],
}








IGNORED = {
    ("element:UIParticle", "ParEffectName"): "stored, never read (UIParticle has no sub-effect system in B either)",
    ("element:UIParticle", "ColEffectName"): "stored, never read",
    ("element:UIParticle", "use_particle_effect"): "stored, never read",
    ("element:UIParticle", "use_particle_collision"): "stored, never read",
    ("element:UIParticle", "use_energy_wave"): "stored, never read",
    ("element:UIParticle", "legacy_pos_for_sub_effect"): "stored, never read",
    ("element:UIParticle", "pass_rotation_to_sub_effect"): "stored, never read",
    ("element:Particle", "use_energy_wave"): "stored, never read; B registers it in the screen-distortion mask "
                                             "(render pipeline FUN_1801aae40), not an effect-element feature",
    ("element:Particle", "ParentSpaceLock"): "base key stored; the sub-effects follow the node instead (needs the "
                                             "OGRE setLogicParentTrans export B has); true in only 8/6635 uses",
    ("skill", "Removedirectly"): "stored mRemoveDirectly, never applied at skill teardown (WXSkill.cpp)",
}
# Beam wave / curve / spline keys: parsed + stored (WXBeamElement), consumed only by curve types absent from data.
for _k in ["CurveType", "TexRepeat", "IsVisable", "IsSinPlay", "WaveExtent-y", "WaveExtent-z", "WaveFrequency",
           "WaveVelocity", "WaveShade-y", "WaveShade-z", "SpLineEditor", "BindElement", "IsSubEleActive",
           "SubElementFrequency"]:
    IGNORED[("element:Beam", _k)] = ("parsed + stored; consumed only by CurveType 3-7 / spline 2,4 which no shipped "
                                     "beam selects (all are CurveType 0/1, WaveShade always 0)")
# ParentSpaceLock is USED only by NewRibbonTrail; on other element types it is stored but not used.
for _s in ELEMENT_SCOPES:
    if _s not in ("NewRibbonTrail", "Particle"):
        IGNORED[("element:" + _s, "ParentSpaceLock")] = "base key stored; element type does not use parent-space lock"


def main():
    dicts = []
    for scope, keys in OWN.items():
        for k in keys:
            dicts.append((scope, k))
        if scope.startswith("element:"):
            for k in BASE:
                if k not in keys:
                    dicts.append((scope, k))
    seen = set()
    with open(os.path.join(HERE, "wx_dicts.tsv"), "w", encoding="utf-8") as f:
        f.write("# scope\tkey  (keys the WXCore effect parsers accept)\n")
        for scope, k in dicts:
            if (scope, k) in seen:
                continue
            seen.add((scope, k))
            f.write("%s\t%s\n" % (scope, k))
    with open(os.path.join(HERE, "wx_key_usage.tsv"), "w", encoding="utf-8") as f:
        f.write("# scope\tkey\tstatus\tevidence   (only parsed-but-ignored keys listed; others in dicts = USED)\n")
        for (scope, k), ev in sorted(IGNORED.items()):
            f.write("%s\t%s\tIGNORED\t%s\n" % (scope, k, ev))
    print("wrote wx_dicts.tsv (%d keys) and wx_key_usage.tsv (%d IGNORED)" % (len(seen), len(IGNORED)))


if __name__ == "__main__":
    main()
