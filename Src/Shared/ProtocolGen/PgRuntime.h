// ProtocolGen runtime - bounds-checked little-endian Reader/Writer, packet base class and the
// helpers the generated codecs use. Template: CY-Source/Tools/protocol/cpp_templates/PgRuntime.h,
// copied verbatim into Src/Shared/ProtocolGen by Tools/protocol/codegen_cpp.py.
//
// Wire facts (Registry/protocol/packets.yaml `framing` / `wire`):
//   frame    = {u16 id, u16 size, u16 idx} little-endian (6 bytes) + `size` body bytes (<= 65535)
//   integers = little-endian; f32 = IEEE-754; bool = 1 byte (server readbool: byte == 1)
//   bytes[N] = fixed N bytes; the server's writer cuts text at a UTF-8 boundary and pads with NUL
//   strN     = u8/u16/u32 byte count + bytes; strings are UTF-8 on the wire
// No dependency on the 0.85 net code (SocketInputStream/SocketOutputStream). ASCII only.
#ifndef CYS_PROTOCOLGEN_PGRUNTIME_H
#define CYS_PROTOCOLGEN_PGRUNTIME_H

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

namespace pg {

enum class Proto : uint8_t { Game = 0, Login = 1 };
// Direction as named by the server: CG/CGW/CL = client -> server (the server decodes with bis()),
// GC/WGC/LC = server -> client (the server encodes with bos()).
enum class Dir : uint8_t { CG = 0, GC = 1, CGW = 2, WGC = 3, CL = 4, LC = 5 };

inline bool isClientToServer(Dir d) { return d == Dir::CG || d == Dir::CGW || d == Dir::CL; }
const char* dirName(Dir d);
const char* protoName(Proto p);

const size_t kFrameHeaderSize = 6;
const size_t kMaxBody = 65535;
// Upper bound for any element count taken from the wire (a body is at most 65535 bytes).
const uint32_t kMaxElements = 65536;

// ------------------------------------------------------------------ logging hook
// Truncations and other non-fatal events are reported here (default: dropped).
typedef void (*LogFn)(const char* message);
void setLogHandler(LogFn fn);
void logf(const char* fmt, ...);

// ------------------------------------------------------------------ UTF-8 helpers
// Largest n <= limit such that bytes [0, n) do not end inside a UTF-8 sequence. Identical to the
// server's bostream:write(s, N) / wire_charset.truncate_utf8_bytes: walk back from `limit` while the
// byte at the cut position is a continuation byte (0x80..0xBF). Returns len when len <= limit.
inline size_t utf8Cut(const void* data, size_t len, size_t limit) {
    if (len <= limit) return len;
    const uint8_t* b = static_cast<const uint8_t*>(data);
    size_t i = limit;
    while (i > 0) {
        const uint8_t c = b[i];
        if (c < 0x80 || c >= 0xC0) break;
        --i;
    }
    return i;
}
inline void truncateUtf8(std::string& s, size_t limit) { s.resize(utf8Cut(s.data(), s.size(), limit)); }

// Fixed-size text field (bytes[N]): same cut + NUL padding as the server writer.
template <size_t N>
inline void setText(std::array<uint8_t, N>& dst, const char* s, size_t len) {
    const size_t n = utf8Cut(s, len, N);
    if (n) std::memcpy(dst.data(), s, n);
    if (n < N) std::memset(dst.data() + n, 0, N - n);
}
template <size_t N>
inline void setText(std::array<uint8_t, N>& dst, const std::string& s) {
    setText(dst, s.data(), s.size());
}
// Text up to the first NUL (how the game reads fixed text fields).
template <size_t N>
inline std::string getText(const std::array<uint8_t, N>& src) {
    size_t n = 0;
    while (n < N && src[n] != 0) ++n;
    return std::string(reinterpret_cast<const char*>(src.data()), n);
}

// ------------------------------------------------------------------ Reader
// Never reads past its window; every accessor returns false on a short read and records the first
// error (a static string), the field (when the generated code knows it) and its body offset.
class Reader {
public:
    Reader() : p_(nullptr), n_(0), pos_(0), base_(0), body_(0), err_(nullptr), field_(nullptr), errPos_(0) {}
    Reader(const void* data, size_t size)
        : p_(static_cast<const uint8_t*>(data)), n_(size), pos_(0), base_(0), body_(size), err_(nullptr),
          field_(nullptr), errPos_(0) {}

    size_t size() const { return n_; }
    size_t pos() const { return pos_; }
    size_t remaining() const { return n_ - pos_; }
    // Size of the whole packet body (the spec's #__body__), also inside sub-readers.
    size_t bodySize() const { return body_; }
    bool ok() const { return err_ == nullptr; }
    const char* error() const { return err_ ? err_ : ""; }
    const char* errorField() const { return field_ ? field_ : ""; }
    size_t errorPos() const { return errPos_; }

    // Record a failure (first one wins; a later call may still name the field) and return false.
    bool fail(const char* what, const char* field = nullptr) {
        if (!err_) {
            err_ = what;
            field_ = field;
            errPos_ = base_ + pos_;
        } else if (!field_ && field) {
            field_ = field;
        }
        return false;
    }
    // Copy the first error of a sub-reader (blob) into this reader.
    bool failFrom(const Reader& sub) {
        if (!err_) {
            err_ = sub.err_ ? sub.err_ : "sub-stream error";
            field_ = sub.field_;
            errPos_ = sub.errPos_;
        }
        return false;
    }

    bool u8(uint8_t& v) {
        if (n_ - pos_ < 1) return fail("short read");
        v = p_[pos_++];
        return true;
    }
    bool i8(int8_t& v) {
        uint8_t u = 0;
        if (!u8(u)) return false;
        v = static_cast<int8_t>(u);
        return true;
    }
    // Lua readbool is (byte == 1); the raw byte is kept so that a round trip is exact.
    bool b8(uint8_t& v) { return u8(v); }
    bool u16(uint16_t& v) {
        if (n_ - pos_ < 2) return fail("short read");
        v = static_cast<uint16_t>(p_[pos_] | (p_[pos_ + 1] << 8));
        pos_ += 2;
        return true;
    }
    bool i16(int16_t& v) {
        uint16_t u = 0;
        if (!u16(u)) return false;
        v = static_cast<int16_t>(u);
        return true;
    }
    bool u32(uint32_t& v) {
        if (n_ - pos_ < 4) return fail("short read");
        v = static_cast<uint32_t>(p_[pos_]) | (static_cast<uint32_t>(p_[pos_ + 1]) << 8) |
            (static_cast<uint32_t>(p_[pos_ + 2]) << 16) | (static_cast<uint32_t>(p_[pos_ + 3]) << 24);
        pos_ += 4;
        return true;
    }
    bool i32(int32_t& v) {
        uint32_t u = 0;
        if (!u32(u)) return false;
        v = static_cast<int32_t>(u);
        return true;
    }
    bool u64(uint64_t& v) {
        if (n_ - pos_ < 8) return fail("short read");
        uint32_t lo = 0, hi = 0;
        u32(lo);
        u32(hi);
        v = (static_cast<uint64_t>(hi) << 32) | lo;
        return true;
    }
    bool f32(float& v) {
        uint32_t u = 0;
        if (!u32(u)) return false;
        std::memcpy(&v, &u, 4);
        return true;
    }

    bool bytes(void* dst, size_t n) {
        if (n_ - pos_ < n) return fail("short read");
        if (n) std::memcpy(dst, p_ + pos_, n);
        pos_ += n;
        return true;
    }
    template <size_t N>
    bool fixed(std::array<uint8_t, N>& dst) {
        return bytes(dst.data(), N);
    }
    bool str(std::string& dst, size_t n) {
        if (n_ - pos_ < n) return fail("short read");
        dst.assign(reinterpret_cast<const char*>(p_ + pos_), n);
        pos_ += n;
        return true;
    }
    bool skip(size_t n) {
        if (n_ - pos_ < n) return fail("short read");
        pos_ += n;
        return true;
    }
    // Carve the next n bytes as an independent sub-reader (kind: blob) and advance past them.
    bool sub(size_t n, Reader& out) {
        if (n_ - pos_ < n) return fail("short read");
        out = Reader(p_ + pos_, n);
        out.base_ = base_ + pos_;
        out.body_ = body_;
        pos_ += n;
        return true;
    }
    // Reject element counts that cannot fit before anything is allocated.
    bool checkCount(uint64_t count, size_t minElemSize, const char* field) {
        if (count > kMaxElements) return fail("element count over limit", field);
        if (minElemSize && count * minElemSize > remaining()) return fail("element count exceeds body", field);
        return true;
    }

private:
    const uint8_t* p_;
    size_t n_, pos_, base_, body_;
    const char* err_;
    const char* field_;
    size_t errPos_;
};

// ------------------------------------------------------------------ Writer
// Appends to an internal buffer; a counting writer only measures (Packet::wireSize()).
class Writer {
public:
    Writer() : count_(0), countOnly_(false) {}
    static Writer counter() {
        Writer w;
        w.countOnly_ = true;
        return w;
    }

    void u8(uint8_t v) {
        if (countOnly_) {
            ++count_;
            return;
        }
        buf_.push_back(v);
    }
    void i8(int8_t v) { u8(static_cast<uint8_t>(v)); }
    void b8(uint8_t v) { u8(v); }
    void u16(uint16_t v) {
        u8(static_cast<uint8_t>(v));
        u8(static_cast<uint8_t>(v >> 8));
    }
    void i16(int16_t v) { u16(static_cast<uint16_t>(v)); }
    void u32(uint32_t v) {
        u8(static_cast<uint8_t>(v));
        u8(static_cast<uint8_t>(v >> 8));
        u8(static_cast<uint8_t>(v >> 16));
        u8(static_cast<uint8_t>(v >> 24));
    }
    void i32(int32_t v) { u32(static_cast<uint32_t>(v)); }
    void u64(uint64_t v) {
        u32(static_cast<uint32_t>(v));
        u32(static_cast<uint32_t>(v >> 32));
    }
    void f32(float v) {
        uint32_t u = 0;
        std::memcpy(&u, &v, 4);
        u32(u);
    }
    void bytes(const void* data, size_t n) {
        if (countOnly_) {
            count_ += n;
            return;
        }
        if (!n) return;
        const uint8_t* b = static_cast<const uint8_t*>(data);
        buf_.insert(buf_.end(), b, b + n);
    }
    template <size_t N>
    void fixed(const std::array<uint8_t, N>& src) {
        bytes(src.data(), N);
    }
    void fill(uint8_t v, size_t n) {
        if (countOnly_) {
            count_ += n;
            return;
        }
        buf_.insert(buf_.end(), n, v);
    }
    // First min(n, len) bytes of the value, NUL-padded to exactly n (speccodec / string.pack("cN")).
    void padded(const void* data, size_t len, size_t n) {
        const size_t take = len < n ? len : n;
        bytes(data, take);
        if (take < n) fill(0, n - take);
    }
    void padded(const std::string& s, size_t n) { padded(s.data(), s.size(), n); }

    size_t size() const { return countOnly_ ? count_ : buf_.size(); }
    const std::vector<uint8_t>& buffer() const { return buf_; }
    std::vector<uint8_t>& buffer() { return buf_; }
    void clear() {
        buf_.clear();
        count_ = 0;
    }

private:
    std::vector<uint8_t> buf_;
    size_t count_;
    bool countOnly_;
};

// ------------------------------------------------------------------ Lua-semantics helpers for conditions
// Conditions in the spec keep Lua 5.3 semantics: integers wrap, '/' is float division, '//' floors,
// '%' is floored, shifts are logical 64-bit. None of these helpers can trap or invoke undefined behaviour.
inline int64_t ladd(int64_t a, int64_t b) {
    return static_cast<int64_t>(static_cast<uint64_t>(a) + static_cast<uint64_t>(b));
}
inline int64_t lsub(int64_t a, int64_t b) {
    return static_cast<int64_t>(static_cast<uint64_t>(a) - static_cast<uint64_t>(b));
}
inline int64_t lmul(int64_t a, int64_t b) {
    return static_cast<int64_t>(static_cast<uint64_t>(a) * static_cast<uint64_t>(b));
}
inline int64_t lneg(int64_t a) { return static_cast<int64_t>(0ULL - static_cast<uint64_t>(a)); }
inline double ldiv(double a, double b) { return a / b; }
inline int64_t lfloor(int64_t v) { return v; }
inline int64_t lfloor(double v) {
    if (v != v) return 0;
    if (v >= 9.2e18) return INT64_MAX;
    if (v <= -9.2e18) return INT64_MIN;
    const int64_t t = static_cast<int64_t>(v);
    return (static_cast<double>(t) > v) ? t - 1 : t;
}
inline int64_t lceil(int64_t v) { return v; }
inline int64_t lceil(double v) {
    if (v != v) return 0;
    if (v >= 9.2e18) return INT64_MAX;
    if (v <= -9.2e18) return INT64_MIN;
    const int64_t t = static_cast<int64_t>(v);
    return (static_cast<double>(t) < v) ? t + 1 : t;
}
inline int64_t lidiv(int64_t a, int64_t b) {
    if (b == 0) return 0;
    if (b == -1) return lneg(a);
    int64_t q = a / b;
    if ((a % b != 0) && ((a < 0) != (b < 0))) --q;
    return q;
}
inline int64_t lmod(int64_t a, int64_t b) {
    if (b == 0 || b == -1) return 0;
    int64_t m = a % b;
    if (m != 0 && ((m < 0) != (b < 0))) m += b;
    return m;
}
inline int64_t lshl(int64_t a, int64_t n) {
    if (n <= -64 || n >= 64) return 0;
    if (n < 0) return static_cast<int64_t>(static_cast<uint64_t>(a) >> (-n));
    return static_cast<int64_t>(static_cast<uint64_t>(a) << n);
}
inline int64_t lshr(int64_t a, int64_t n) {
    if (n <= -64 || n >= 64) return 0;
    return lshl(a, -n);
}
inline int64_t lmin(int64_t a, int64_t b) { return a < b ? a : b; }
inline int64_t lmax(int64_t a, int64_t b) { return a > b ? a : b; }
inline double lmin(double a, double b) { return a < b ? a : b; }
inline double lmax(double a, double b) { return a > b ? a : b; }
inline int64_t labs(int64_t a) { return a < 0 ? lneg(a) : a; }
inline double labs(double a) { return a < 0 ? -a : a; }

// 1-based element read used by conditions (Lua t[i]); out of range reads as 0.
template <class T, size_t N>
inline int64_t at1(const std::array<T, N>& a, int64_t i) {
    return (i >= 1 && i <= static_cast<int64_t>(N)) ? static_cast<int64_t>(a[static_cast<size_t>(i - 1)]) : 0;
}
template <class T>
inline int64_t at1(const std::vector<T>& a, int64_t i) {
    return (i >= 1 && i <= static_cast<int64_t>(a.size())) ? static_cast<int64_t>(a[static_cast<size_t>(i - 1)]) : 0;
}
template <class T>
inline int64_t at1(const T* a, size_t n, int64_t i) {
    return (i >= 1 && i <= static_cast<int64_t>(n)) ? static_cast<int64_t>(a[static_cast<size_t>(i - 1)]) : 0;
}
template <class C>
inline bool inRange(const C& c, int64_t i) {
    return i >= 1 && i <= static_cast<int64_t>(c.size());
}
// `<field>_wirelen` of a length-prefixed string holds the decoded prefix when it differed from the data
// (guard false, clamp, or a negative signed prefix); kAutoLen - outside every prefix range - means
// "derive the prefix from the string size".
const int64_t kAutoLen = INT64_MIN;
inline int64_t wlen(const std::string& s, int64_t wirelen) {
    return wirelen != kAutoLen ? wirelen : static_cast<int64_t>(s.size());
}

// ------------------------------------------------------------------ derived server state
// GCCharBaseAttrib (annotations.py char_base_attrib_flags): rebuild m_uFlags[1..11] and the two DFeng
// flag bytes from the 14 wire bytes new_flags (combat.lua bos shifts bit 7 onwards up by one bit).
void deriveCharBaseAttribFlags(const uint8_t newFlags[14], int64_t uFlags[11], int64_t* dfengFlags,
                               int64_t* dfengFlags2);
// GCDetailAttrib_Pet (annotations.py detail_attrib_pet_flags): rebuild m_Flags[1..11] (old layout)
// and the rage / elf presence bits from the 12 remapped wire bytes _nf.
void deriveDetailAttribPetFlags(const uint8_t nf[12], int64_t flags[11], bool* hasRage, bool* hasRageMax,
                                bool* elfFlag);

// ------------------------------------------------------------------ packets
// Method names avoid the field names of the spec (id, name, size ... are common fields).
class Packet {
public:
    virtual ~Packet() {}
    virtual uint16_t packetId() const = 0;
    virtual Proto packetProto() const = 0;
    virtual Dir packetDir() const = 0;
    virtual const char* packetName() const = 0;
    // Decode the fields from r. Returns false (never throws, never reads out of bounds) on short or
    // inconsistent data; r.error() / r.errorField() / r.errorPos() tell why. Trailing bytes are the
    // caller's business (see decodePacket).
    virtual bool read(Reader& r) = 0;
    // Encode the fields. Never fails; over-long strings are cut at a UTF-8 boundary to the spec limit.
    virtual void write(Writer& w) const = 0;
    // Encoded body size in bytes.
    size_t wireSize() const {
        Writer w = Writer::counter();
        write(w);
        return w.size();
    }
};

struct FrameHeader {
    uint16_t id;
    uint16_t size;
    uint16_t idx;
};
inline bool readFrameHeader(const void* data, size_t n, FrameHeader& h) {
    if (n < kFrameHeaderSize) return false;
    const uint8_t* b = static_cast<const uint8_t*>(data);
    h.id = static_cast<uint16_t>(b[0] | (b[1] << 8));
    h.size = static_cast<uint16_t>(b[2] | (b[3] << 8));
    h.idx = static_cast<uint16_t>(b[4] | (b[5] << 8));
    return true;
}
inline void writeFrameHeader(std::vector<uint8_t>& out, const FrameHeader& h) {
    const uint8_t b[6] = {static_cast<uint8_t>(h.id),   static_cast<uint8_t>(h.id >> 8),
                          static_cast<uint8_t>(h.size), static_cast<uint8_t>(h.size >> 8),
                          static_cast<uint8_t>(h.idx),  static_cast<uint8_t>(h.idx >> 8)};
    out.insert(out.end(), b, b + 6);
}

}  // namespace pg

#endif  // CYS_PROTOCOLGEN_PGRUNTIME_H
