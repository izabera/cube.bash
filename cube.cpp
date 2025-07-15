#include <string>
#include <fmt/format.h>
#include <cstdint>
#include <string_view>

using u64 = uint64_t;
using u32 = uint32_t;
using u16 = uint16_t;
using u8 = uint8_t;

// template <int size = 3>
// requires requires { size >= 1; }
struct cube {
    std::array<u8, 8> co{}, cp{0,1,2,3,4,5,6,7};
    std::array<u8, 12> eo{}, ep{0,1,2,3,4,5,6,7,8,9,10,11};
    //struct piece { unsigned char o:2, p:4; };
    //piece c[8]{}, e[12]{};
    //u8 co[12]{}, cp[12]{}, eo[8]{}, ep[8]{};
    //u16 ep{}, eo{}, co{};
    //u32 cp{};

    enum cubie {
        URB, UBR=URB, RBU, RUB=RBU, BRU, BUR=BRU,
        ULB, UBL=ULB, LBU, LUB=LBU, BLU, BUL=BLU,
        URF, UFR=URF, RFU, RUF=RFU, FRU, FUR=FRU,
        ULF, UFL=ULF, LFU, LUF=LFU, FLU, FUL=FLU,
        DRB, DBR=DRB, RBD, RDB=RBD, BRD, BDR=BRD,
        DLB, DBL=DLB, LBD, LDB=LBD, BLD, BDL=BLD,
        DRF, DFR=DRF, RFD, RDF=RFD, FRD, FDR=FRD,
        DLF, DFL=DLF, LFD, LDF=LFD, FLD, FDL=FLD,
        UB, UR, UF, UL,
        LU, LF, LD, LB,
        FU, FR, FD, FL,
        RU, RB, RD, RF,
        BU, BL, BD, BR,
        DF, DR, DB, DL,
    };

    constexpr cube(std::string_view = "");
    constexpr cube(const char *s) : cube(std::string_view(s)) {}
    //constexpr cube(std::span<piece>);
    constexpr cube(std::span<cubie>);
    constexpr cube operator~() const { return *this; }
    constexpr cube &operator+(const cube &) { return *this; }
    constexpr const cube operator+(const cube &) const { return *this; }
    constexpr bool operator==(const cube &) const;
    constexpr std::string to_string() const;
    constexpr static cube random_scramble();

#if 0
   speffz            cp               co               ep               eo

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

    void debug() const {
        constexpr static const char *col[] = {
            "\x1b[48;5;231m  \x1b[m\x1b[31m", // white
            "\x1b[48;5;202m  \x1b[m\x1b[31m", // orange
            "\x1b[48;5;034m  \x1b[m\x1b[31m", // green
            "\x1b[48;5;196m  \x1b[m\x1b[31m", // red
            "\x1b[48;5;021m  \x1b[m\x1b[31m", // blue
            "\x1b[48;5;220m  \x1b[m\x1b[31m", // yellow
        };
        constexpr static const char *c[8][3] = {
            {col[0], col[1], col[4]}, // U
            {col[0], col[4], col[3]},
            {col[0], col[3], col[2]},
            {col[0], col[2], col[1]},
            {col[5], col[1], col[2]}, // D
            {col[5], col[2], col[3]},
            {col[5], col[3], col[4]},
            {col[5], col[4], col[1]},
        };
        constexpr static const char *e[12][2] = {
            {col[0], col[4]}, {col[0], col[3]}, {col[0], col[2]}, {col[0], col[1]}, // U
            {col[4], col[1]}, {col[2], col[1]}, {col[2], col[3]}, {col[4], col[3]}, // E
            {col[5], col[2]}, {col[5], col[3]}, {col[5], col[4]}, {col[5], col[1]}, // D
        };

        auto a = 10, b = 11;

        const char *cube[6*9] = {
            col[0], col[1], col[2], col[3], col[4], col[5],

            c[cp[0]][(co[0]+0)%3], c[cp[1]][(co[1]+0)%3], c[cp[2]][(co[2]+0)%3], c[cp[3]][(co[3]+0)%3], // U
            c[cp[0]][(co[0]+1)%3], c[cp[3]][(co[3]+2)%3], c[cp[4]][(co[4]+1)%3], c[cp[7]][(co[7]+2)%3], // L
            c[cp[3]][(co[3]+1)%3], c[cp[2]][(co[2]+2)%3], c[cp[5]][(co[5]+1)%3], c[cp[4]][(co[4]+2)%3], // F
            c[cp[2]][(co[2]+1)%3], c[cp[1]][(co[1]+2)%3], c[cp[6]][(co[6]+1)%3], c[cp[5]][(co[5]+2)%3], // R
            c[cp[1]][(co[1]+1)%3], c[cp[0]][(co[0]+2)%3], c[cp[7]][(co[7]+1)%3], c[cp[6]][(co[6]+2)%3], // B
            c[cp[4]][(co[4]+0)%3], c[cp[5]][(co[5]+0)%3], c[cp[6]][(co[6]+0)%3], c[cp[7]][(co[7]+0)%3], // D

            e[ep[0]][ eo[0]], e[ep[1]][ eo[1]], e[ep[2]][ eo[2]], e[ep[3]][ eo[3]], // U
            e[ep[3]][!eo[3]], e[ep[5]][!eo[5]], e[ep[b]][!eo[b]], e[ep[4]][!eo[4]], // L
            e[ep[2]][!eo[2]], e[ep[6]][ eo[6]], e[ep[8]][!eo[8]], e[ep[5]][ eo[5]], // F
            e[ep[1]][!eo[1]], e[ep[7]][!eo[7]], e[ep[9]][!eo[9]], e[ep[6]][!eo[6]], // R
            e[ep[0]][!eo[0]], e[ep[4]][ eo[4]], e[ep[a]][!eo[a]], e[ep[7]][ eo[7]], // B
            e[ep[8]][ eo[8]], e[ep[9]][ eo[9]], e[ep[a]][ eo[a]], e[ep[b]][ eo[b]], // D
        };

        auto lookup = [&](auto id) {
            return cube[id >= '0' && id <= '5' ? id - '0' :
                        id >= 'A' && id <= 'X' ? id - 'A' + 6 : id - 'a' + 30];
        };
#define L(x) lookup(x[0]), lookup(x[1]), lookup(x[2])

        printf("      %s%s%s\x1b[m\n"
               "      %s%s%s\x1b[m\n"
               "      %s%s%s\x1b[m\n"
               "%s%s%s%s%s%s%s%s%s%s%s%s\x1b[m\n"
               "%s%s%s%s%s%s%s%s%s%s%s%s\x1b[m\n"
               "%s%s%s%s%s%s%s%s%s%s%s%s\x1b[m\n"
               "      %s%s%s\x1b[m\n"
               "      %s%s%s\x1b[m\n"
               "      %s%s%s\x1b[m\n",
                         L("AaB"),
                         L("d0b"),
                         L("Dcc"),
               L("EeF"), L("IiJ"), L("MmN"), L("QqR"),
               L("h1f"), L("l2j"), L("p3n"), L("t4r"),
               L("HgG"), L("LkK"), L("PoO"), L("TsS"),
                         L("UuV"),
                         L("x5v"),
                         L("XwW"));
    }
};

constexpr cube::cube(std::string_view) {
}
constexpr auto operator""_cube(const char *s, size_t) { return cube{s}; }

int main() {
    auto c = cube();
    c.debug();
    puts("==");
    c.cp = {1,2,3,0,4,5,6,7};
    c.ep = {1,2,3,0,4,5,6,7,8,9,10,11};
    c.debug();
    puts("==");
    c.cp = {2,3,0,1,5,6,7,4};
    c.ep = {2,3,0,1,4,5,6,7,9,10,11,8};
    c.debug();
    cube("R U R' U'") + "L2 d2";
    // Cube<4>::random_scramble().to_string();
    [[maybe_unused]] constexpr auto x = ~"R"_cube;
}
