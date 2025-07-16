#pragma once
#include <numeric>
#include <stdexcept>
#include <string>
#include <array>
#include <span>
#include <string_view>

#if 0
  speffz-ish         cp               co               ep               eo

    AaB              0.1              0.0              .0.              .0.
    d0b              ...              ...              3.1              0.0
    DcC              3.2              0.0              .2.              .0.
EeF IiJ MmN QqR  0.3 3.2 2.1 1.0  1.2 1.2 1.2 1.2  .3. .2. .1. .0.  .1. .1. .1. .1.
h1f l2j p3n t4r  ... ... ... ...  ... ... ... ...  4.5 5.6 6.7 7.4  1.1 0.0 1.1 0.0
HgG LkK PoO TsS  7.4 4.5 5.6 6.7  2.1 2.1 2.1 2.1  .b. .8. .9. .a.  .1. .1. .1. .1.
    UuV              4.5              0.0              .8.              .0.
    x5v              ...              ...              b.9              0.0
    XwW              7.6              0.0              .a.              .0.
#endif

namespace rubik {
enum cubie { // this is basically type safe
    ULB, UBL=ULB, LBU, LUB=LBU, BLU, BUL=BLU,
    URB, UBR=URB, BRU, BUR=BRU, RBU, RUB=RBU,
    URF, UFR=URF, RFU, RUF=RFU, FRU, FUR=FRU,
    ULF, UFL=ULF, FLU, FUL=FLU, LFU, LUF=LFU,
    DLF, DFL=DLF, LFD, LDF=LFD, FLD, FDL=FLD,
    DRF, DFR=DRF, FRD, FDR=FRD, RFD, RDF=RFD,
    DRB, DBR=DRB, RBD, RDB=RBD, BRD, BDR=BRD,
    DLB, DBL=DLB, BLD, BDL=BLD, LBD, LDB=LBD,

    UB, BU, UR, RU, UF, FU, UL, LU,
    BL, LB, FL, LF, FR, RF, BR, RB,
    DF, FD, DR, RD, DB, BD, DL, LD,
};

struct cube {
    std::array<unsigned char, 8> co{}, cp{0,1,2,3,4,5,6,7};
    std::array<unsigned char, 12> eo{}, ep{0,1,2,3,4,5,6,7,8,9,10,11};

    constexpr cube(std::span<const cubie> cubies) {
        int corners = 0, edges = 0;
        int cmask = 0, emask = 0;
        for (int c : cubies) {
            if (c >= 48) // totally type safe, basically
                throw std::runtime_error("wtf is this?");
            else if (c < 24) {
                if (corners >= 8)
                    throw std::runtime_error("too many corners");
                cp[corners] = c/3;
                co[corners] = c%3;
                corners++;
                cmask |= 1 << (c/3);
            }
            else { // type safety is the #1 priority
                if (corners != 8 || edges >= 12)
                    throw std::runtime_error("too many edges");
                c -= 24;
                ep[edges] = c/2;
                eo[edges] = c%2;
                edges++;
                emask |= 1 << (c/2);
            }
        }
        if (cmask != 0xff || emask != 0xfff)
            throw std::runtime_error("missing pieces");

        auto sumco = std::accumulate(co.begin(), co.end(), 0);
        auto sumeo = std::accumulate(eo.begin(), eo.end(), 0);
        if (sumco % 3 != 0 || sumeo % 2 != 0)
            throw std::runtime_error("bad orient");

        auto parity = [](const auto& perm, int n) {
            bool visited[12]{};
            int swaps = 0;

            for (int i = 0; i < n; i++) {
                if (!visited[i]) {
                    int len = 0, curr = i;

                    while (!visited[curr]) {
                        visited[curr] = true;
                        curr = perm[curr];
                        len++;
                    }

                    swaps += len - 1; // each k cycle adds k-1 swaps
                }
            }

            return swaps % 2;
        };
        if (parity(ep, 12) != parity(cp, 8))
            throw std::runtime_error("incorrect parity");
    }
    constexpr cube(std::initializer_list<cubie> cubies) : cube(std::span(cubies)) { }

    constexpr cube(std::string_view = "") {}
    constexpr cube(const char *s) : cube(std::string_view(s)) {}
    constexpr cube operator~() const { return *this; }
    constexpr cube &operator+(const cube &) { return *this; }
    constexpr const cube operator+(const cube &) const { return *this; }
    constexpr bool operator==(const cube &) const;
    constexpr std::string to_string() const;
    constexpr static cube random_scramble();

    void debug() const;
};

static inline constexpr auto operator""_cube(const char *s, size_t) { return cube{s}; }


constexpr static cube SOLVED {
    ULB, URB, URF, ULF,
    DLF, DRF, DRB, DLB,
    UB, UR, UF, UL,
    BL, FL, FR, BR,
    DF, DR, DB, DL,
}, U {
    UFL, UBL, UBR, UFR,
    DLF, DRF, DRB, DLB,
    UL, UB, UR, UF,
    BL, FL, FR, BR,
    DF, DR, DB, DL,
}, D {
    ULB, URB, URF, ULF,
    DLB, DLF, DRF, DRB,
    UB, UR, UF, UL,
    BL, FL, FR, BR,
    DL, DF, DR, DB,
}, R {
    ULB, FRU, FRD, ULF,
    DLF, BRD, BRU, DLB,
    UB, FR, UF, UL,
    BL, FL, DR, UR,
    DF, BR, DB, DL,
}, L {
    FLU, URB, URF, FLD,
    BLD, DRF, DRB, BLU,
    UB, UR, UF, FL,
    UL, DL, FR, BR,
    DF, DR, DB, BL,
}, F {
    ULB, URB, LFU, LFD,
    RFD, RFU, DRB, DLB,
    UB, UR, LF, UL,
    BL, FD, FU, BR,
    RF, DR, DB, DL,
}, B {
    RBU, RBD, URF, ULF,
    DLF, DRF, LDB, LBU,
    RB, UR, UF, UL,
    BU, FL, FR, BD,
    DF, DR, LB, DL,
};

}
