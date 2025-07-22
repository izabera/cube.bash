# todo: make this look less awful
show () {
    local cp=("${@:1:8}") co=("${@:9:8}") ep=("${@:17:12}") eo=("${@:29:12}")

    if [[ $EMOJI ]]; then
        local col=(⬜️ 🟧 🟩 🟥 🟦 🟨)
    else
        local col=($'\e[48;5;'{231,202,34,196,21,220}$'m  \e[m')
    fi

    local c=(
        "${col[0]}" "${col[1]}" "${col[4]}" # U
        "${col[0]}" "${col[4]}" "${col[3]}"
        "${col[0]}" "${col[3]}" "${col[2]}"
        "${col[0]}" "${col[2]}" "${col[1]}"
        "${col[5]}" "${col[1]}" "${col[2]}" # D
        "${col[5]}" "${col[2]}" "${col[3]}"
        "${col[5]}" "${col[3]}" "${col[4]}"
        "${col[5]}" "${col[4]}" "${col[1]}"
    )
    local e=(
        "${col[0]}" "${col[4]}" "${col[0]}" "${col[3]}" "${col[0]}" "${col[2]}" "${col[0]}" "${col[1]}" # U
        "${col[4]}" "${col[1]}" "${col[2]}" "${col[1]}" "${col[2]}" "${col[3]}" "${col[4]}" "${col[3]}" # E
        "${col[5]}" "${col[2]}" "${col[5]}" "${col[3]}" "${col[5]}" "${col[4]}" "${col[5]}" "${col[1]}" # D
    )
    local a=10 b=11

    local cube=(
        "${col[0]}" "${col[1]}" "${col[2]}" "${col[3]}" "${col[4]}" "${col[5]}"

        "${c[cp[0]*3+(co[0]+0)%3]}" "${c[cp[1]*3+(co[1]+0)%3]}" "${c[cp[2]*3+(co[2]+0)%3]}" "${c[cp[3]*3+(co[3]+0)%3]}" # U
        "${c[cp[0]*3+(co[0]+1)%3]}" "${c[cp[3]*3+(co[3]+2)%3]}" "${c[cp[4]*3+(co[4]+1)%3]}" "${c[cp[7]*3+(co[7]+2)%3]}" # L
        "${c[cp[3]*3+(co[3]+1)%3]}" "${c[cp[2]*3+(co[2]+2)%3]}" "${c[cp[5]*3+(co[5]+1)%3]}" "${c[cp[4]*3+(co[4]+2)%3]}" # F
        "${c[cp[2]*3+(co[2]+1)%3]}" "${c[cp[1]*3+(co[1]+2)%3]}" "${c[cp[6]*3+(co[6]+1)%3]}" "${c[cp[5]*3+(co[5]+2)%3]}" # R
        "${c[cp[1]*3+(co[1]+1)%3]}" "${c[cp[0]*3+(co[0]+2)%3]}" "${c[cp[7]*3+(co[7]+1)%3]}" "${c[cp[6]*3+(co[6]+2)%3]}" # B
        "${c[cp[4]*3+(co[4]+0)%3]}" "${c[cp[5]*3+(co[5]+0)%3]}" "${c[cp[6]*3+(co[6]+0)%3]}" "${c[cp[7]*3+(co[7]+0)%3]}" # D

        "${e[ep[0]*2+ eo[0]]}" "${e[ep[1]*2+ eo[1]]}" "${e[ep[2]*2+ eo[2]]}" "${e[ep[3]*2+ eo[3]]}" # U
        "${e[ep[3]*2+!eo[3]]}" "${e[ep[5]*2+!eo[5]]}" "${e[ep[b]*2+!eo[b]]}" "${e[ep[4]*2+!eo[4]]}" # L
        "${e[ep[2]*2+!eo[2]]}" "${e[ep[6]*2+ eo[6]]}" "${e[ep[8]*2+!eo[8]]}" "${e[ep[5]*2+ eo[5]]}" # F
        "${e[ep[1]*2+!eo[1]]}" "${e[ep[7]*2+!eo[7]]}" "${e[ep[9]*2+!eo[9]]}" "${e[ep[6]*2+!eo[6]]}" # R
        "${e[ep[0]*2+!eo[0]]}" "${e[ep[4]*2+ eo[4]]}" "${e[ep[a]*2+!eo[a]]}" "${e[ep[7]*2+ eo[7]]}" # B
        "${e[ep[8]*2+ eo[8]]}" "${e[ep[9]*2+ eo[9]]}" "${e[ep[a]*2+ eo[a]]}" "${e[ep[b]*2+ eo[b]]}" # D
    )

    local layout=(
              A a B
              d 0 b
              D c C
        E e F I i J M m N Q q R
        h 1 f l 2 j p 3 n t 4 r
        H g G L k K P o O T s S
              U u V
              x 5 v
              X w W
    )

    local -A lookup
    local i

    for i in {0..5} {A..X} {a..x}; do
        lookup[$i]=${#lookup[@]}
    done

    for i in "${!layout[@]}"; do
        layout[i]=${cube[lookup[${layout[i]}]]}
    done

    local fmt=
    fmt+=$'      %s%s%s\n'
    fmt+=$'      %s%s%s\n'
    fmt+=$'      %s%s%s\n'
    fmt+=$'%s%s%s%s%s%s%s%s%s%s%s%s\n'
    fmt+=$'%s%s%s%s%s%s%s%s%s%s%s%s\n'
    fmt+=$'%s%s%s%s%s%s%s%s%s%s%s%s\n'
    fmt+=$'      %s%s%s\n'
    fmt+=$'      %s%s%s\n'
    fmt+=$'      %s%s%s\n'

    printf "$fmt" "${layout[@]}"
}
