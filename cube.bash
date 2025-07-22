#!/bin/bash

LANG=C
set -f

declare -A cubies=(
    [ULB]=0  [UBL]=0   [LBU]=1   [LUB]=1   [BLU]=2   [BUL]=2  
    [URB]=3  [UBR]=3   [BRU]=4   [BUR]=4   [RBU]=5   [RUB]=5  
    [URF]=6  [UFR]=6   [RFU]=7   [RUF]=7   [FRU]=8   [FUR]=8  
    [ULF]=9  [UFL]=9   [FLU]=10  [FUL]=10  [LFU]=11  [LUF]=11 
    [DLF]=12 [DFL]=12  [LFD]=13  [LDF]=13  [FLD]=14  [FDL]=14 
    [DRF]=15 [DFR]=15  [FRD]=16  [FDR]=16  [RFD]=17  [RDF]=17 
    [DRB]=18 [DBR]=18  [RBD]=19  [RDB]=19  [BRD]=20  [BDR]=20 
    [DLB]=21 [DBL]=21  [BLD]=22  [BDL]=22  [LBD]=23  [LDB]=23 

    [UB]=24 [BU]=25 [UR]=26 [RU]=27 [UF]=28 [FU]=29 [UL]=30 [LU]=31
    [BL]=32 [LB]=33 [FL]=34 [LF]=35 [FR]=36 [RF]=37 [BR]=38 [RB]=39
    [DF]=40 [FD]=41 [DR]=42 [RD]=43 [DB]=44 [BD]=45 [DL]=46 [LD]=47
)

cube () {
    local i c cube
    for ((;i<$#;i++)) do
        c=${cubies[${@:i+1:1}]}
        if ((i<8)); then
            ((cube[i]=c/3, cube[i+8]=c%3))
        else
            ((cube[i+16]=(c-24)/2, cube[i+28]=(c-24)%2))
        fi
    done
    REPLY=${cube[*]}
}



add () {
    local lhscp=("${@: 1:8}") lhsco=("${@: 9:8}") lhsep=("${@:17:12}") lhseo=("${@:29:12}")
    local rhscp=("${@:41:8}") rhsco=("${@:49:8}") rhsep=("${@:57:12}") rhseo=("${@:69:12}")
    local {c,e}{p,o} i cube

    for ((i=0;i<8;i++)) do
        ((cp[i]=lhscp[rhscp[i]], co[i]=(lhsco[rhscp[i]]+rhsco[i])%3))
    done
    for ((i=0;i<12;i++)) do
        ((ep[i]=lhsep[rhsep[i]], eo[i]=(lhseo[rhsep[i]]+rhseo[i])%2))
    done

    cube=("${cp[@]}" "${co[@]}" "${ep[@]}" "${eo[@]}")
    REPLY=${cube[*]}
}

invert () {
    local cp=("${@:1:8}") co=("${@:9:8}") ep=("${@:17:12}") eo=("${@:29:12}")
    local inv{c,e}{p,o} i cube

    for ((i=0;i<8;i++)) do
        ((invcp[cp[i]]=i, invco[i]=(3-co[invcp[i]])%3))
    done
    for ((i=0;i<12;i++)) do
        ((invep[ep[i]]=i, inveo[i]=(2-eo[invep[i]])%2))
    done
}



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




declare -A moves

cube ULB URB URF ULF   DLF DRF DRB DLB   UB UR UF UL   BL FL FR BR   DF DR DB DL; SOLVED=$REPLY
cube UFL UBL UBR UFR   DLF DRF DRB DLB   UL UB UR UF   BL FL FR BR   DF DR DB DL; moves[U]=$REPLY
cube ULB URB URF ULF   DLB DLF DRF DRB   UB UR UF UL   BL FL FR BR   DL DF DR DB; moves[D]=$REPLY
cube ULB FRU FRD ULF   DLF BRD BRU DLB   UB FR UF UL   BL FL DR UR   DF BR DB DL; moves[R]=$REPLY
cube BLD URB URF BLU   FLU DRF DRB FLD   UB UR UF BL   DL UL FR BR   DF DR DB FL; moves[L]=$REPLY
cube ULB URB LFU LFD   RFD RFU DRB DLB   UB UR LF UL   BL FD FU BR   RF DR DB DL; moves[F]=$REPLY
cube RBU RBD URF ULF   DLF DRF LDB LBU   RB UR UF UL   BU FL FR BD   DF DR LB DL; moves[B]=$REPLY

for m in U D F B R L; do
    add ${moves[$m]} ${moves[$m]};   moves[$m\2]=$REPLY
    add ${moves[$m]} ${moves[$m\2]}; moves[$m\']=$REPLY
done



domoves () {
    REPLY=$SOLVED
    for m do add $REPLY ${moves[$m]}; done
}

#demo () {
#    printf %s\\n "$1"
#    shift
#    domoves "$@"
#    show $REPLY
#}
#
#demo solved
#demo checkerboard U2 D2 R2 L2 F2 B2
#demo sune R U R\' U R U2 R\'
#demo tperm R U R\' U\' R\' F R2 U\' R\' U\' R U R\' F\'




[[ $VERBOSE ]] && alias verbose= || alias verbose=#
shopt -s expand_aliases

showtime () {
    local t=$(($2-$1))
    printf '\r%s%s.%03ds\e[K\n' "${3+$3: }" "$((t/1000000))" "$(((t%1000000)/1000))"
}




bfs () {
    local tonum=$1 allowed=("${@:2}")
    local queue=("$SOLVED") q
    local currnum nextnum nextstate
    "$tonum" $SOLVED
    bfs[$REPLY]=0

    for ((;q<${#queue[@]};q++)); do
        verbose printf '%s\e[K\r' "$q"
        "$tonum" ${queue[q]}
        currnum=$REPLY
        for m in "${allowed[@]}"; do
            add ${queue[q]} ${moves[$m]}
            nextstate=$REPLY
            "$tonum" $nextstate
            nextnum=$REPLY
            [[ -v bfs[$nextnum] ]] && continue
            queue+=("$nextstate")
            ((bfs[$nextnum]=bfs[$currnum]+1))
        done
    done
}

eotonum () {
    local eo=("${@:29:12}") IFS=
    let "REPLY=2#${eo[*]}" # stupid vim hl
}
cotonum () {
    local co=("${@:9:8}") IFS=
    let "REPLY=3#${co[*]}"
}
ud1tonum () {
    local ep=("${@:17:12}") i IFS=
    for i in {0..11}; do
        ((ep[i]=ep[i]>=4&&ep[i]<=7))
    done
    let "REPLY=2#${ep[*]}"
}
eptonum () {
    local ep=("${@:17:12}") i
    REPLY=0
    for i in {0..11}; do
        ((i<4||i>7))&&((REPLY*=12,REPLY+=ep[i]))
    done
}
cptonum () {
    local cp=("${@:1:8}") i
    REPLY=0
    for i in {0..7}; do
        ((REPLY*=8,REPLY+=cp[i]))
    done
}
ud2tonum () {
    local ep=("${@:17:12}") i IFS=
    REPLY=0
    for i in {0..11}; do
        ((i>=4&&i<=7))&&((REPLY*=12,REPLY+=ep[i]))
    done
}



prune () {
    echo -n "$1" pruning table...
    declare -gn bfs="$1prune"
    t0=${EPOCHREALTIME/.}
    bfs "$1tonum" "${@:2}"
    t1=${EPOCHREALTIME/.}
    showtime "$t0" "$t1" "$1prune"
}

[[ -e prunes ]] && source ./prunes || {
    : > prunes

    for prune in eo co ud1; do
        declare -A "$prune"prune
        prune "$prune" {U,D,F,B,L,R}{,2,\'}
        declare -p "$prune"prune >> prunes
    done

    for prune in ep cp ud2; do
        declare -A "$prune"prune
        prune "$prune" {U,D}{,2,\'} {F,B,L,R}2
        declare -p "$prune"prune >> prunes
    done

# very slow but it's a one time cost
# eoprune: 7.174s
# coprune: 7.790s
# ud1prune: 1.973s
# epprune: 119.318s
# cpprune: 116.474s
# ud2prune: 0.049s
# eo=2048 co=2187 ud1=495 ep=40320 cp=40320 ud2=24

}

echo eo=${#eoprune[@]} co=${#coprune[@]} ud1=${#ud1prune[@]} ep=${#epprune[@]} cp=${#cpprune[@]} ud2=${#ud2prune[@]}




# no U U, no D U, yes U D
declare -A badnext=([U]=U [D]=UD [R]=R [L]=RL [F]=F [B]=FB)

idastar () {
    local lvl=$((lvl+1)) next max h
    local state=${*:2} m sofar=
    verbose echo
    for m in "${allowed[@]}"; do
        verbose printf '%*slvl=%s m=%s\e[K\r' "$lvl" '' "$lvl" "$sofar$m"
        [[ $m = [${badnext[$1]}]* ]] && continue
        verbose sofar+="$m "
        verbose ((ida++))
        add $state ${moves[$m]}
        next=$REPLY

        max=0
        # h is an admissible heuristic for a* that always returns a nonnegative integer
        for h in "${heuristics[@]}"; do
            "$h"tonum $next
            ((h=${h}prune[$REPLY],max=max<h?h:max,lvl+h<depth)) || continue 2
        done

        ((max==0)) && {
            verbose echo
            break=1
            stack[lvl]=$m
            return
        }
        idastar ${m::1} $next && { stack[lvl]=$m; return; }
    done
    verbose printf '\e[A\e[J'
    return 1
}


searchdepth () {
    local break=0 ida=0 t0 t1
    for ((depth=2;!break;depth++)) do
        echo depth=$((depth-1))
        t0=${EPOCHREALTIME/.}
        idastar Z $state; e=$?
        t1=${EPOCHREALTIME/.}
        showtime "$t0" "$t1"
        ((e)) || break
    done
    verbose echo $ida states checked
}


simplify () {
    set "${@//\'/3}"
    set "${@/%[^23]/&1}"
    local IFS= join='(.*)(.)([123])\2([123])(.*)'
    REPLY=$*
    while [[ $REPLY =~ $join ]]; do
        REPLY=${BASH_REMATCH[1]}${BASH_REMATCH[2]}$((BASH_REMATCH[3]+BASH_REMATCH[4]))${BASH_REMATCH[5]}
        REPLY=${REPLY//5/1}
        REPLY=${REPLY//6/2}
        REPLY=${REPLY//?4}
    done
    REPLY=${REPLY//[123]/& }
    REPLY=${REPLY//1}
    REPLY=${REPLY//3/\'}
}

solve () {
    echo ===solving===
    show "$@"

    local depth state=$* heuristics allowed t

    t[0]=${EPOCHREALTIME/.}
    echo phase1
    heuristics=(eo co ud1) allowed=({F,B,L,R,U,D}{,2,\'})
    searchdepth
    solution=(${stack[@]}) stack=()
    domoves ${solution[@]}
    add $state $REPLY
    state=$REPLY
    t[1]=${EPOCHREALTIME/.}

    echo phase2
    heuristics=(ep cp ud2) allowed=({U,D}{,2,\'} {F,B,L,R}2)
    searchdepth
    solution+=(${stack[@]})
    simplify "${solution[@]}"
    solution=($REPLY)
    t[2]=${EPOCHREALTIME/.}

    showtime "${t[0]}" "${t[1]}" phase1
    showtime "${t[1]}" "${t[2]}" phase2
    echo "solution: ${solution[*]} (${#solution[@]} HTM)"
}

#RANDOM=7
#m=({U,D,F,B,L,R}{,2,\'}) scramble=()
#for _ in {1..25}; do
#    scramble+=(${m[RANDOM%18]})
#done
#scramble=(R F2 L U)
#scramble=(${@-R2 F2 U F L B})
if (( $# )); then
    echo scramble: "$@"
    domoves "$@"
    solve $REPLY
else
    FLIPPY="0 1 2 3 4 5 6 7 0 0 0 0 0 0 0 0 0 1 2 3 4 5 6 7 8 9 10 11 0 0 0 0 0 1 1 0 0 0 0 0"
    solve $FLIPPY
fi
