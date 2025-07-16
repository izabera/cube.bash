#include "cube.hpp"

void rubik::cube::debug(std::string_view message) const {
    if (message != "") {
        auto msg = std::string(message);
        puts(msg.data());
    }

    // clang-format off
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
                     L("DcC"),
           L("EeF"), L("IiJ"), L("MmN"), L("QqR"),
           L("h1f"), L("l2j"), L("p3n"), L("t4r"),
           L("HgG"), L("LkK"), L("PoO"), L("TsS"),
                     L("UuV"),
                     L("x5v"),
                     L("XwW"));
    // clang-format on
}

int main() {
    using namespace rubik;
    //auto c = cube();
    //c.debug();
    //puts("==");
    //c.cp = {1,2,3,0,4,5,6,7};
    //c.ep = {1,2,3,0,4,5,6,7,8,9,10,11};
    //c.debug();
    //puts("==");
    //c.cp = {2,3,0,1,5,6,7,4};
    //c.ep = {2,3,0,1,4,5,6,7,9,10,11,8};
    //c.debug();
    //cube("R U R' U'") + "L2 d2";
    //// Cube<4>::random_scramble().to_string();
    //[[maybe_unused]] constexpr auto x = ~"R"_cube;

    SOLVED.debug("solved");
    U.debug("U");
    D.debug("D");
    R.debug("R");
    L.debug("L");
    F.debug("F");
    B.debug("B");

    cube x;   x.debug("solved" );
    x += U;   x.debug("U"      );
    x += D;   x.debug("U D"    );
    x += U;   x.debug("U2 D"   );
    x += U;   x.debug("U' D"   );
    x += D;   x.debug("U' D2"  );
    x += D;   x.debug("U' D'"  );
    x += U;   x.debug("D'"     );
    x += D;   x.debug("solved" );
    x += U*2; x.debug("U2"     );
    x += R;   x.debug("U2 R"   );
    x += R;   x.debug("U2 R2"  );
    x += U;   x.debug("U2 R2 U");
    x = {};   x.debug("solved" );
    x = (R + U) * 3;
    x.debug("(RU)3");
    x = {};   x.debug("solved" );
    x = (F + U) * 3;
    x.debug("(FU)3");
    x = {};   x.debug("solved" );
    x = ~R;
    x.debug("R'");

    constexpr auto sexy = R + U + ~R + ~U;
    constexpr auto rurf = R + U + ~R + ~F;
    constexpr auto sledge = ~R + F + R + ~F;
    //constexpr auto fruruf = F + R + U + ~R + ~U + ~F;
    constexpr auto fisholl = F + R + ~U + ~R + ~U + rurf;
    constexpr auto toll = sexy + sledge;
    fisholl.debug("fisholl");
    toll.debug("toll");
    constexpr auto yperm = fisholl + toll;
    yperm.debug("yperm");
    constexpr auto tperm = R + U + ~R + ~U + ~R + F + R*2 + ~U + ~R + ~U + R + U + ~R + ~F;
    tperm.debug("tperm");
    x = tperm*2;
    x.debug("solved");
    static_assert(tperm*2 == SOLVED);
    static_assert(tperm*-2 == SOLVED);
    (L + ~D).debug("D'");
    (L + ~D + L).debug("aperm");
}
