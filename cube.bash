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

# todo: convert add to do this and make it work with all its callers
add2 () {
    local rhscp=("${@: 1:8}") rhsco=("${@: 9:8}") rhsep=("${@:17:12}") rhseo=("${@:29:12}") i

    for ((i=0;i<8;i++)) do
        ((nextcp[i]=cp[rhscp[i]], nextco[i]=(co[rhscp[i]]+rhsco[i])%3))
    done
    for ((i=0;i<12;i++)) do
        ((nextep[i]=ep[rhsep[i]], nexteo[i]=(eo[rhsep[i]]+rhseo[i])%2))
    done
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



source ./ui.bash




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





[[ $VERBOSE ]] && alias verbose= || alias verbose=#
shopt -s expand_aliases

showtime () {
    local t=$(($2-$1))
    printf '\r%s%s.%03ds\e[m\e[K\n' "${3+$3:$' \e[32m'}" "$((t/1000000))" "$(((t%1000000)/1000))"
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
    let "REPLY=2#${eo[*]}"
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

# since holding a table with <1M elements in memory doesn't seem to be a problem in 2025,
# and since value lookup is far from the bottleneck for bash,
# here's a couple of experimental pruning heuristics

# eo + u co = 2**11*3**4 = 165888
eoucotonum () {
    local co=("${@:9:4}") eo=("${@:29:12}") IFS=
    let "REPLY=3#${co[*]}<<12|2#${eo[*]}"
}
# co + u eo = 3**7*2**4 = 36992
coueotonum () {
    local co=("${@:9:8}") eo=("${@:29:4}") IFS=
    let "REPLY=3#${co[*]}<<4|2#${eo[*]}"
}


# todo: convert all tonum functions and their callers use these
eotonum2 () {
    local -n eo=$1eo
    local IFS=
    let "REPLY=2#${eo[*]}"
}
cotonum2 () {
    local -n co=$1co
    local IFS=
    let "REPLY=3#${co[*]}"
}
ud1tonum2 () {
    local -n ep=$1ep
    local IFS=
    for i in {0..11}; do
        ((tmp[i]=ep[i]>=4&&ep[i]<=7))
    done
    let "REPLY=2#${tmp[*]}"
}
eptonum2 () {
    local -n ep=$1ep
    REPLY=0
    for i in {0..11}; do
        ((i<4||i>7))&&((REPLY*=12,REPLY+=ep[i]))
    done
}
cptonum2 () {
    local -n cp=$1cp
    REPLY=0
    for i in {0..7}; do
        ((REPLY*=8,REPLY+=cp[i]))
    done
}
ud2tonum2 () {
    local -n ep=$1ep
    REPLY=0
    for i in {0..11}; do
        ((i>=4&&i<=7))&&((REPLY*=12,REPLY+=ep[i]))
    done
}
eoucotonum2 () {
    local -n co=$1co eo=$1eo
    local IFS=
    let "REPLY=3#${co[*]::4}<<12|2#${eo[*]}"
}
coueotonum2 () {
    local -n co=$1co eo=$1eo
    local IFS=
    let "REPLY=3#${co[*]}<<4|2#${eo[*]:0:4}"
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

    for prune in eouco coueo eo co ud1; do
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

echo eo=${#eoprune[@]} co=${#coprune[@]} ud1=${#ud1prune[@]} \
     ep=${#epprune[@]} cp=${#cpprune[@]} ud2=${#ud2prune[@]} \
     eouco=${#eoucoprune[@]} coueo=${#coueoprune[@]}




# no U U, no D U, yes U D
declare -A badnext=([U]=U [D]=UD [R]=R [L]=RL [F]=F [B]=FB)

idastar () {
    local lvl=$((lvl+1)) max h m sofar \
          cp=("${@:2:8}") co=("${@:10:8}") ep=("${@:18:12}") eo=("${@:30:12}")
    verbose echo
    for m in "${allowed[@]}"; do
        verbose printf '%*slvl=%s m=%s\e[K\r' "$lvl" '' "$lvl" "$sofar$m"
        [[ $m = [${badnext[$1]}]* ]] && continue
        verbose sofar+="$m "
        verbose ((ida++))
        add2 ${moves[$m]}

        max=0
        # h is an admissible heuristic for a* that always returns a nonnegative integer
        for h in "${heuristics[@]}"; do
            "$h"tonum2 next
            ((h=${h}prune[$REPLY],max=max<h?h:max,lvl+h<depth)) || continue 2
        done

        ((max==0)) && {
            verbose echo
            break=1
            stack[lvl]=$m
            return
        }
        idastar ${m::1} ${nextcp[*]} ${nextco[*]} ${nextep[*]} ${nexteo[*]} && { stack[lvl]=$m; return; }
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
    verbose printf '\e[32m%s\e[m states reached\n' "$ida"
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

# quickly check that the current phase isn't already solved
quickcheck () {
    for h in "${heuristics[@]}"; do
        "$h"tonum "$@"
        ((${h}prune[$REPLY])) && return
    done
    return 1
}

solve () {
    echo ===solving===
    show "$@"

    local depth state=$* heuristics allowed t


    echo phase1
    t[0]=${EPOCHREALTIME/.}
    heuristics=(eouco coueo ud1) allowed=({F,B,L,R}{,\'} {F,B,R,L}2 {U,D}{,2,\'})
    if quickcheck $state; then
        searchdepth
        solution=(${stack[@]}) stack=()
        domoves ${solution[@]}
        add $state $REPLY
        state=$REPLY
    fi
    t[1]=${EPOCHREALTIME/.}

    echo phase2
    t[2]=${EPOCHREALTIME/.}
    heuristics=(ep cp ud2) allowed=({U,D}{,2,\'} {F,B,L,R}2)
    if quickcheck $state; then
        searchdepth
        solution+=(${stack[@]})
    fi
    t[3]=${EPOCHREALTIME/.}

    simplify "${solution[@]}"
    solution=($REPLY)

    showtime "${t[0]}" "${t[1]}" phase1
    showtime "${t[2]}" "${t[3]}" phase2
    printf 'solution: \e[32m%s\e[m (\e[32m%s\e[m HTM)\e[m\n' "${solution[*]}" "${#solution[@]}"
}

FLIPPY="0 1 2 3 4 5 6 7 0 0 0 0 0 0 0 0 0 1 2 3 4 5 6 7 8 9 10 11 0 0 0 0 0 1 1 0 0 0 0 0"

if (( TEST )); then
    path=(L F\' D F2 D\' F L)
    REPLY=$FLIPPY
    echo initial
    set Z $REPLY
    show ${*:2}

    heuristics=(eouco coueo eo co ud1)
    allowed=({F,B,L,R}{,\'} {F,B,R,L}2 {U,D}{,2,\'})

    for m in ${path[@]}; do
        echo lvl=$((++lvl))
        cp=("${@:2:8}") co=("${@:10:8}") ep=("${@:18:12}") eo=("${@:30:12}")
        #for m in "${allowed[@]}"; do
        [[ $m = [${badnext[$1]}]* ]] && continue
        echo m=$m
        add2 ${moves[$m]}
        show ${nextcp[*]} ${nextco[*]} ${nextep[*]} ${nexteo[*]}
        set $m ${nextcp[*]} ${nextco[*]} ${nextep[*]} ${nexteo[*]}
        max=0
        for h in "${heuristics[@]}"; do
            "$h"tonum2 next
            r1=$REPLY
            "$h"tonum ${nextcp[*]} ${nextco[*]} ${nextep[*]} ${nexteo[*]}
            r2=$REPLY
            printf '%-30s%s\n' "build ${h}prune[$r1]=$((${h}prune[$r1]))" "lookup ${h}prune[$r2]=$((${h}prune[$r2]))"
        done
        echo
    done
    exit
fi
#RANDOM=7
#m=({U,D,F,B,L,R}{,2,\'}) scramble=()
#for _ in {1..25}; do
#    scramble+=(${m[RANDOM%18]})
#done
#scramble=(R F2 L U)
#scramble=(${@-R2 F2 U F L B})
if (( $# )); then
    echo scramble: "$@"
    domoves $*
    solve $REPLY
else
    solve $FLIPPY
fi
