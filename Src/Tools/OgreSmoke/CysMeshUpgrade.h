// CYS: CPU-only, hash-pinned conversion of the two CY login scene meshes.
// No renderer, optimisation, material substitution, or skeleton export is used.
#ifndef CYS_MESH_UPGRADE_H
#define CYS_MESH_UPGRADE_H

#include <windows.h>
#include <wincrypt.h>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <map>
#include <set>
#include <stdexcept>
#include <string>
#include <vector>
#include "Ogre.h"
#include "OgreDefaultHardwareBufferManager.h"
#include "OgreMeshSerializer.h"
#include "OgreSubMesh.h"
#include "OgreSkeleton.h"
#pragma comment(lib, "advapi32.lib")

namespace CysMeshUpgrade
{
    typedef std::vector<unsigned char> Bytes;
    inline void require(bool ok, const char* reason)
    {
        if (!ok) throw std::runtime_error(reason);
    }

    struct Handle
    {
        HANDLE value;
        explicit Handle(HANDLE v) : value(v) {}
        ~Handle() { if (value != INVALID_HANDLE_VALUE) CloseHandle(value); }
    private:
        Handle(const Handle&);
        Handle& operator=(const Handle&);
    };

    inline std::string sha256(const void* data, size_t length)
    {
        require(length <= 16 * 1024 * 1024, "hash-size-cap");
        HCRYPTPROV provider = 0;
        HCRYPTHASH hash = 0;
        require(CryptAcquireContextA(&provider, NULL, NULL, PROV_RSA_AES,
                                    CRYPT_VERIFYCONTEXT) != 0, "hash-provider");
        bool ok = CryptCreateHash(provider, CALG_SHA_256, 0, 0, &hash) != 0;
        if (ok) ok = CryptHashData(hash, static_cast<const BYTE*>(data),
                                  static_cast<DWORD>(length), 0) != 0;
        BYTE digest[32];
        DWORD size = sizeof(digest);
        if (ok) ok = CryptGetHashParam(hash, HP_HASHVAL, digest, &size, 0) != 0;
        if (hash) CryptDestroyHash(hash);
        CryptReleaseContext(provider, 0);
        require(ok && size == sizeof(digest), "hash-failed");
        const char* hex = "0123456789abcdef";
        std::string result;
        for (size_t i = 0; i < sizeof(digest); ++i)
        { result += hex[digest[i] >> 4]; result += hex[digest[i] & 15]; }
        return result;
    }

    inline std::string lower(std::string s)
    {
        for (size_t i = 0; i < s.size(); ++i)
            if (s[i] >= 'A' && s[i] <= 'Z') s[i] += 'a' - 'A';
        return s;
    }

    // Paths supplied on the CLI are ASCII. Resource keys inside the pinned
    // mesh remain GBK bytes, represented by CP1252 names on the private disk.
    inline std::string absolute(const std::string& value)
    {
        require(!value.empty() && value.size() < MAX_PATH - 32, "path-length");
        for (size_t i = 0; i < value.size(); ++i)
            require(static_cast<unsigned char>(value[i]) >= 32 &&
                    static_cast<unsigned char>(value[i]) < 127, "path-not-ascii");
        require(value.find('~') == std::string::npos, "path-short-name");
        char full[MAX_PATH];
        DWORD n = GetFullPathNameA(value.c_str(), MAX_PATH, full, NULL);
        require(n > 3 && n < MAX_PATH && full[1] == ':' && full[2] == '\\',
                "path-not-local-drive");
        std::string result(full);
        require(result.find(':', 2) == std::string::npos, "path-stream");
        std::string drive = result.substr(0, 3);
        require(GetDriveTypeA(drive.c_str()) == DRIVE_FIXED, "path-not-fixed-drive");
        return result;
    }

    inline void checkParents(const std::string& path, bool missingLeaf = false)
    {
        for (size_t pos = 3; pos <= path.size(); ++pos)
        {
            if (pos < path.size() && path[pos] != '\\') continue;
            std::string part = path.substr(0, pos);
            DWORD attr = GetFileAttributesA(part.c_str());
            if (attr == INVALID_FILE_ATTRIBUTES && missingLeaf && pos == path.size())
            {
                require(GetLastError() == ERROR_FILE_NOT_FOUND, "missing-parent");
                continue;
            }
            require(attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_REPARSE_POINT),
                    "path-missing-or-reparse");
            if (pos < path.size()) require((attr & FILE_ATTRIBUTE_DIRECTORY) != 0, "parent-not-directory");
        }
    }

    inline std::string checkout()
    {
        char current[MAX_PATH];
        DWORD n = GetCurrentDirectoryA(MAX_PATH, current);
        require(n > 0 && n < MAX_PATH, "cwd-unavailable");
        std::string root = absolute(current);
        checkParents(root);
        require(lower(root.substr(root.find_last_of('\\') + 1)) == "cy-source", "cwd-not-cy-source");
        require(GetFileAttributesA((root + "\\Src\\CMakeLists.txt").c_str()) != INVALID_FILE_ATTRIBUTES &&
                GetFileAttributesA((root + "\\Timeline\\handoff\\net.md").c_str()) != INVALID_FILE_ATTRIBUTES,
                "checkout-markers-absent");
        return root;
    }

    inline std::string privatePath(const std::string& path, const std::string& root,
                                   bool newFile = false)
    {
        std::string result = absolute(path);
        std::string prefix = lower(root + "\\Build\\");
        require(lower(result).compare(0, prefix.size(), prefix) == 0, "path-outside-build");
        checkParents(result, newFile);
        if (newFile) require(GetFileAttributesA(result.c_str()) == INVALID_FILE_ATTRIBUTES,
                             "output-already-exists");
        return result;
    }

    inline Bytes readFile(const std::string& path)
    {
        checkParents(path);
        Handle file(CreateFileA(path.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL,
                                OPEN_EXISTING, FILE_FLAG_OPEN_REPARSE_POINT, NULL));
        require(file.value != INVALID_HANDLE_VALUE, "input-open");
        BY_HANDLE_FILE_INFORMATION info;
        require(GetFileInformationByHandle(file.value, &info) != 0 && info.nNumberOfLinks == 1 &&
                !(info.dwFileAttributes & (FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_REPARSE_POINT)) &&
                info.nFileSizeHigh == 0 && info.nFileSizeLow > 0 && info.nFileSizeLow <= 8 * 1024 * 1024,
                "input-kind-or-size");
        Bytes data(info.nFileSizeLow);
        DWORD read = 0;
        require(ReadFile(file.value, &data[0], info.nFileSizeLow, &read, NULL) != 0 &&
                read == info.nFileSizeLow, "input-short-read");
        return data;
    }

    inline void reserve(const std::string& path)
    {
        checkParents(path, true);
        Handle file(CreateFileA(path.c_str(), GENERIC_WRITE, 0, NULL, CREATE_NEW,
                                FILE_ATTRIBUTE_NORMAL, NULL));
        require(file.value != INVALID_HANDLE_VALUE, "output-reservation");
    }

    struct Fixture
    {
        const char* id;
        const char* meshHash;
        const char* skeletonHash;
        const char* key;
        size_t vertices, triangles, bones;
    };

    inline const Fixture& identify(const Bytes& data)
    {
        static const Fixture fixtures[] = {
            {"bird", "1dcb85938d9a93ff88d4fa82df4d8c1c9499691fee1663f28635d12b87dce417",
             "605509a85e43e4853c16a305a00722761f8b1763743bc74746657775c236fec7",
             "\xb7\xc9\xc4\xf1", 48, 48, 7},
            {"crane", "4f625d68d20157bea39692044ea06dddbb1b8bde628b31715c9ce781886c56ee",
             "05d12a57c08c693b0040819d492ec5fbea4867c35418d8d2619ebe425f59accc",
             "\xd0\xa1\xb6\xaf\xce\xef\xba\xd7", 484, 560, 18}
        };
        const std::string hash = sha256(&data[0], data.size());
        for (size_t i = 0; i < 2; ++i) if (hash == fixtures[i].meshHash) return fixtures[i];
        throw std::runtime_error("input-not-pinned-cy-mesh");
    }

    // MeshSerializer import bypasses Resource::load; explicitly release imported
    // buffers even if import/verification throws. Do not call Mesh::load (which
    // compiles/normalises bone assignments and can change the source geometry).
    class ImportedMesh : public Ogre::Mesh
    {
    public:
        explicit ImportedMesh(const char* name) : Ogre::Mesh(
            Ogre::MeshManager::getSingletonPtr(), name, 0, "CysMeshUpgrade", true, NULL) {}
        ~ImportedMesh() { unloadImpl(); }
    private:
        ImportedMesh(const ImportedMesh&);
        ImportedMesh& operator=(const ImportedMesh&);
    };

    struct Snapshot
    {
        std::string bytes;
        std::vector<std::pair<std::string, size_t> > fields;
        size_t vertices, indices, weights;
        std::set<unsigned short> bones;
        Snapshot() : vertices(0), indices(0), weights(0) {}
        void field(const std::string& name) { fields.push_back(std::make_pair(name, bytes.size())); }
        void number(uint64_t n)
        { for (unsigned i = 0; i < 8; ++i) { bytes += static_cast<char>(n & 255); n >>= 8; } }
        void blob(const void* data, size_t n)
        {
            require(n <= 8 * 1024 * 1024 && bytes.size() + n < 16 * 1024 * 1024,
                    "snapshot-size-cap");
            number(n);
            if (n) bytes.append(static_cast<const char*>(data), n);
        }
        void string(const std::string& s) { blob(s.data(), s.size()); }
        void real(Ogre::Real v)
        { require(std::isfinite(v), "nonfinite-mesh-value"); blob(&v, sizeof(v)); }
        void vector(const Ogre::Vector3& v) { real(v.x); real(v.y); real(v.z); }
        void buffer(Ogre::HardwareBuffer* b)
        {
            require(b && b->getSizeInBytes() > 0 && b->getSizeInBytes() <= 8 * 1024 * 1024,
                    "buffer-size-cap");
            Bytes data(b->getSizeInBytes());
            b->readData(0, data.size(), &data[0]);
            blob(&data[0], data.size());
        }
        void geometry(const Ogre::VertexData* v, const std::string& prefix)
        {
            number(v != NULL);
            field(prefix + ".present");
            if (!v) return;
            require(v->vertexStart == 0 && v->vertexCount > 0 && v->vertexCount <= 1000 &&
                    v->hwAnimationDataList.empty() && v->hardwareShadowVolWBuffer.isNull(),
                    "unsupported-vertex-state");
            vertices += v->vertexCount;
            number(v->vertexStart); number(v->vertexCount);
            field(prefix + ".vertex-range");
            const Ogre::VertexDeclaration::VertexElementList& elems = v->vertexDeclaration->getElements();
            number(elems.size());
            for (Ogre::VertexDeclaration::VertexElementList::const_iterator i = elems.begin(); i != elems.end(); ++i)
            {
                number(i->getSource()); number(i->getOffset()); number(i->getType());
                number(i->getSemantic()); number(i->getIndex());
            }
            field(prefix + ".vertex-declaration");
            const Ogre::VertexBufferBinding::VertexBufferBindingMap& bindings = v->vertexBufferBinding->getBindings();
            number(bindings.size());
            for (Ogre::VertexBufferBinding::VertexBufferBindingMap::const_iterator i = bindings.begin(); i != bindings.end(); ++i)
            {
                require(!i->second.isNull() && i->second->getNumVertices() == v->vertexCount,
                        "vertex-buffer-count");
                number(i->first); number(i->second->getVertexSize());
                buffer(i->second.getPointer());
                field(prefix + ".vertex-buffer-" + std::to_string(i->first));
            }
        }
        template<class Iterator> void assignments(Iterator it, size_t vertexCount, Ogre::Skeleton* skeleton)
        {
            size_t count = 0;
            Snapshot entries;
            while (it.hasMoreElements())
            {
                const Ogre::VertexBoneAssignment& a = it.getNext();
                require(a.vertexIndex < vertexCount && a.weight > 0 && a.weight <= 1 &&
                        skeleton->getBone(a.boneIndex) != NULL, "invalid-bone-assignment");
                entries.number(a.vertexIndex); entries.number(a.boneIndex); entries.real(a.weight);
                bones.insert(a.boneIndex); ++count;
            }
            number(count); string(entries.bytes); weights += count;
        }
    };

    inline Snapshot snapshot(Ogre::Mesh& mesh, const Fixture& f)
    {
        require(mesh.getNumSubMeshes() == 1 && mesh.getNumLodLevels() == 1 &&
                mesh.getPoseList().empty() && mesh.getNumAnimations() == 0 &&
                !mesh.hasVertexAnimation() && !mesh.isEdgeListBuilt() &&
                !mesh.getAutoBuildEdgeLists() && !mesh.isPreparedForShadowVolumes(),
                "unsupported-lod-pose-animation-edge");
        require(mesh.hasSkeleton() && !mesh.getSkeleton().isNull() &&
                mesh.getSkeletonName() == std::string(f.key) + ".skeleton", "skeleton-not-loaded");
        const Ogre::MeshLodUsage& lod = mesh.getLodLevel(0);
        require(lod.fromDepthSquared == 0 && lod.manualName.empty() && lod.edgeData == NULL &&
                lod.manualMesh.isNull(), "unsupported-lod-zero");
        const Ogre::AxisAlignedBox& bounds = mesh.getBounds();
        require(!bounds.isNull() && mesh.getBoundingSphereRadius() > 0,
                "invalid-bounds");
        Snapshot s;
        s.vector(bounds.getMinimum()); s.field("bounds.minimum");
        s.vector(bounds.getMaximum()); s.field("bounds.maximum");
        s.real(mesh.getBoundingSphereRadius()); s.field("bounds.radius");
        s.string(mesh.getSkeletonName());
        s.number(mesh.getSkeleton()->getNumBones()); s.number(mesh.getSkeleton()->getNumAnimations());
        s.field("skeleton.link-and-counts");
        s.geometry(mesh.sharedVertexData, "shared");
        s.assignments(mesh.getBoneAssignmentIterator(), mesh.sharedVertexData ? mesh.sharedVertexData->vertexCount : 0,
                      mesh.getSkeleton().getPointer());
        s.field("shared.bone-assignments");
        std::map<std::string, unsigned short> names;
        const Ogre::Mesh::SubMeshNameMap& sourceNames = mesh.getSubMeshNameMap();
        for (Ogre::Mesh::SubMeshNameMap::const_iterator i = sourceNames.begin(); i != sourceNames.end(); ++i)
            names[i->first] = i->second;
        s.number(names.size());
        for (std::map<std::string, unsigned short>::const_iterator i = names.begin(); i != names.end(); ++i)
        { s.string(i->first); s.number(i->second); }
        s.field("submesh.names");
        Ogre::SubMesh& sub = *mesh.getSubMesh(0);
        require(sub.operationType == Ogre::RenderOperation::OT_TRIANGLE_LIST &&
                sub.getMaterialName() == f.key && sub.mLodFaceList.empty() &&
                sub.blendIndexToBoneIndexMap.empty(), "unsupported-submesh-state");
        s.number(sub.useSharedVertices); s.number(sub.operationType); s.string(sub.getMaterialName());
        s.number(sub.isMatInitialised());
        Ogre::SubMesh::AliasTextureIterator aliases = sub.getAliasTextureIterator();
        s.number(sub.getTextureAliasCount());
        while (aliases.hasMoreElements()) { s.string(aliases.peekNextKey()); s.string(aliases.getNext()); }
        s.field("submesh0.operation-material-aliases");
        require(sub.useSharedVertices ? mesh.sharedVertexData != NULL : sub.vertexData != NULL,
                "submesh-geometry-absent");
        if (!sub.useSharedVertices) s.geometry(sub.vertexData, "submesh0");
        require(sub.indexData && sub.indexData->indexStart == 0 && !sub.indexData->indexBuffer.isNull() &&
                sub.indexData->indexBuffer->getType() == Ogre::HardwareIndexBuffer::IT_16BIT &&
                sub.indexData->indexCount == f.triangles * 3 &&
                sub.indexData->indexBuffer->getNumIndexes() == sub.indexData->indexCount,
                "invalid-index-state");
        s.indices = sub.indexData->indexCount;
        s.number(sub.indexData->indexStart); s.number(s.indices); s.number(sub.indexData->indexBuffer->getType());
        s.buffer(sub.indexData->indexBuffer.getPointer());
        s.field("submesh0.indices");
        const size_t vertexCount = sub.useSharedVertices ?
            (mesh.sharedVertexData ? mesh.sharedVertexData->vertexCount : 0) : sub.vertexData->vertexCount;
        std::vector<unsigned short> indices(s.indices);
        sub.indexData->indexBuffer->readData(0, indices.size() * sizeof(unsigned short), &indices[0]);
        for (size_t i = 0; i < indices.size(); ++i)
            require(indices[i] < vertexCount, "index-outside-vertex-buffer");
        s.assignments(sub.getBoneAssignmentIterator(), vertexCount, mesh.getSkeleton().getPointer());
        s.field("submesh0.bone-assignments");
        require(s.vertices == f.vertices && s.bones.size() == f.bones && s.weights > 0,
                "fixture-count-mismatch");
        return s;
    }

    inline void equal(const Snapshot& before, const Snapshot& after, const char* phase)
    {
        if (before.bytes == after.bytes) return;
        size_t offset = 0;
        while (offset < before.bytes.size() && offset < after.bytes.size() &&
               before.bytes[offset] == after.bytes[offset]) ++offset;
        const char* field = "snapshot-end";
        for (size_t i = 0; i < before.fields.size(); ++i)
            if (offset < before.fields[i].second) { field = before.fields[i].first.c_str(); break; }
        std::fprintf(stderr, "CYS_MESH_UPGRADE mismatch phase=%s field=%s byte=%llu before_size=%llu after_size=%llu\n",
                     phase, field, static_cast<unsigned long long>(offset),
                     static_cast<unsigned long long>(before.bytes.size()),
                     static_cast<unsigned long long>(after.bytes.size()));
        throw std::runtime_error("mesh-roundtrip-invariant-mismatch");
    }

    inline void importMeshBytes(Ogre::MeshSerializer& serializer, Bytes& bytes, Ogre::Mesh& mesh)
    {
        Ogre::DataStreamPtr stream(new Ogre::MemoryDataStream(&bytes[0], bytes.size(), false));
        serializer.importMesh(stream, &mesh);
        require(stream->tell() == bytes.size(), "mesh-input-not-consumed");
    }

    inline int run(int argc, char** argv)
    {
        try
        {
            require(argc == 5, "usage-upgrade-login-mesh-input-output-resources");
            require(GetACP() == 1252, "requires-cp1252-resource-paths");
            const std::string rootPath = checkout();
            const std::string input = privatePath(argv[2], rootPath);
            const std::string output = privatePath(argv[3], rootPath, true);
            const std::string resources = privatePath(argv[4], rootPath);
            const std::string log = privatePath(output + ".log", rootPath, true);
            require((GetFileAttributesA(resources.c_str()) & FILE_ATTRIBUTE_DIRECTORY) != 0,
                    "resources-not-directory");
            Bytes source = readFile(input);
            const Fixture& f = identify(source);
            const std::string skeletonPath = resources + "\\" + f.key + ".skeleton";
            const Bytes skeleton = readFile(skeletonPath);
            require(sha256(&skeleton[0], skeleton.size()) == f.skeletonHash, "skeleton-not-pinned");
            // Reserve both NEW files only after every input and path check.
            reserve(output); reserve(log);
            Snapshot before, after;
            Bytes converted;
            {
                // Buffer manager outlives Root and the imported meshes.
                Ogre::DefaultHardwareBufferManager buffers;
                Ogre::Root root("", "", log);
                require(root.getRenderSystem() == NULL, "unexpected-renderer");
                // readBoundsInfo pads every imported AABB. A converter must
                // preserve file-space bounds, otherwise export + Game load
                // applies that padding twice. Only this private CPU process
                // uses zero; Game retains its normal runtime padding policy.
                Ogre::MeshManager::getSingleton().setBoundsPaddingFactor(0);
                Ogre::ResourceGroupManager::getSingleton().createResourceGroup("CysMeshUpgrade");
                Ogre::ResourceGroupManager::getSingleton().addResourceLocation(
                    resources, "FileSystem", "CysMeshUpgrade", false);
                Ogre::MeshSerializer serializer;
                ImportedMesh original("cys-upgrade-input"), restored("cys-upgrade-output");
                importMeshBytes(serializer, source, original);
                before = snapshot(original, f);
                serializer.exportMesh(&original, output, Ogre::Serializer::ENDIAN_LITTLE);
                converted = readFile(output);
                const char expectedHeader[] = "\x00\x10[MeshSerializer_v1.40]\n";
                const std::string header(expectedHeader, sizeof(expectedHeader) - 1);
                require(converted.size() >= header.size() &&
                        std::memcmp(&converted[0], header.data(), header.size()) == 0, "wrong-output-version");
                importMeshBytes(serializer, converted, restored);
                after = snapshot(restored, f);
                equal(before, after, "roundtrip");
                equal(before, snapshot(original, f), "export-source");
            }
            require(readFile(input) == source && readFile(skeletonPath) == skeleton,
                    "source-or-skeleton-changed");
            std::printf("CYS_MESH_UPGRADE {\"pass\":true,\"fixture\":\"%s\",\"source_sha256\":\"%s\","
                        "\"output_sha256\":\"%s\",\"skeleton_sha256\":\"%s\",\"invariant_sha256\":\"%s\","
                        "\"vertices\":%llu,\"triangles\":%llu,\"bone_ids\":%llu,\"weights\":%llu,"
                        "\"from\":\"1.30\",\"to\":\"1.40\",\"renderer\":false}\n",
                        f.id, f.meshHash, sha256(&converted[0], converted.size()).c_str(), f.skeletonHash,
                        sha256(before.bytes.data(), before.bytes.size()).c_str(),
                        static_cast<unsigned long long>(before.vertices),
                        static_cast<unsigned long long>(before.indices / 3),
                        static_cast<unsigned long long>(before.bones.size()),
                        static_cast<unsigned long long>(before.weights));
            return 0;
        }
        catch (const Ogre::Exception&)
        { std::fprintf(stderr, "CYS_MESH_UPGRADE failure: ogre-exception-see-private-log\n"); }
        catch (const std::exception& e)
        { std::fprintf(stderr, "CYS_MESH_UPGRADE failure: %s\n", e.what()); }
        catch (...)
        { std::fprintf(stderr, "CYS_MESH_UPGRADE failure: native-exception\n"); }
        return 1;
    }
}
#endif
