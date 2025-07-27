#!/bin/bash

source ./defs.bash
source ./ui.bash

# since holding a table with <1M elements in memory doesn't seem to be a problem in 2025,
# and since value lookup is far from the bottleneck for bash,
# this precomputes several rather large tables
if [[ ! -e tables && -e tables.gz ]]; then
    gunzip < tables.gz > tables
elif [[ ! -e tables ]]; then
    source ./gentables.bash
fi
source ./tables

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

domoves () {
    REPLY=$SOLVED
    for m do add $REPLY ${moves[$m]}; done
}

solve () {
    echo ===solving===
    show "$@"

    local depth state=$* heuristics allowed t


    echo phase1
    t[0]=${EPOCHREALTIME/.}
    heuristics=(co eo ud1) allowed=({F,B,L,R}{,\'} {F,B,R,L}2 {U,D}{,2,\'})
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
    FLIPPY="0 1 2 3 4 5 6 7 0 0 0 0 0 0 0 0 0 1 2 3 4 5 6 7 8 9 10 11 0 0 0 0 0 1 1 0 0 0 0 0"
    solve $FLIPPY
fi
