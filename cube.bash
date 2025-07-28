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
declare -A badnext=(
    [U]=U  [U2]=U  [U\']=U
    [D]=UD [D2]=UD [D\']=UD
    [R]=R  [R2]=R  [R\']=R
    [L]=RL [L2]=RL [L\']=RL
    [F]=F  [F2]=F  [F\']=F
    [B]=FB [B2]=FB [B\']=FB
)

# h=(co eo ud1) or h=(cp ep ud2)
idastar () {
    local lvl=$((lvl+1)) m this=("${@:2}") next sofar
    verbose echo

    for m in "${allowed[@]}"; do
        verbose printf '%*slvl=%s m=%s\e[K\r' "$lvl" '' "$lvl" "$sofar$m"
        [[ $m != [${badnext[$1]}]* ]] || continue
        sofar+="$m "
        ((ida++))
        ((lvl+${h[0]}prune[$((next[0]=${h[0]}trans[${this[0]}$m]))]<depth)) &&
        ((lvl+${h[1]}prune[$((next[1]=${h[1]}trans[${this[1]}$m]))]<depth)) &&
        ((lvl+${h[2]}prune[$((next[2]=${h[2]}trans[${this[2]}$m]))]<depth)) || continue

        stack[lvl]=$m
        ((next[0]==goal[0]&&next[1]==goal[1]&&next[2]==goal[2])) && return 0
        idastar "$m" "${next[@]}" && return
    done
    verbose printf '\e[A\e[J'
    return 1
}

searchdepth () {
    local break=0 ida=0 t0 t1 state=$*
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
quickcheck () (($1!=goal[0]||$2!=goal[1]||$3!=goal[2]))

domoves () for m do add $REPLY ${moves[$m]}; done

solve () {
    echo ===solving===
    toshow "$@"

    local depth state=($*) h allowed t stack=()
    local solved=($SOLVED) solution=()

    echo phase1
    t[0]=${EPOCHREALTIME/.}
    phase1state=(${state[1]} ${state[3]} ${state[4]})
    goal=(${solved[1]} ${solved[3]} ${solved[4]})
    h=(co eo ud1)
    allowed=({F,B,L,R}{,\'} {F,B,R,L}2 {U,D}{,2,\'})
    if quickcheck ${phase1state[@]}; then
        searchdepth ${phase1state[@]}
        solution=(${stack[@]}) stack=()
        REPLY=$*
        domoves ${solution[@]}
        state=($REPLY)
    fi
    t[1]=${EPOCHREALTIME/.}

    echo phase2
    t[2]=${EPOCHREALTIME/.}
    phase2state=(${state[0]} ${state[6]} ${state[5]}) # restricted ep
    goal=(${solved[0]} ${solved[6]} ${solved[5]})
    h=(cp ep ud2)
    allowed=({U,D}{,2,\'} {F,B,L,R}2)
    if quickcheck ${phase2state[@]}; then
        searchdepth ${phase2state[@]}
        solution+=(${stack[@]})
    fi
    t[3]=${EPOCHREALTIME/.}

    simplify "${solution[@]}"
    solution=($REPLY) stack=()

    showtime "${t[0]}" "${t[1]}" phase1
    showtime "${t[2]}" "${t[3]}" phase2
    printf 'solution: \e[32m%s\e[m (\e[32m%s\e[m HTM)\e[m\n' "${solution[*]}" "${#solution[@]}"
}

if (( $# )); then
    echo scramble: "$@"
    REPLY=$SOLVED
    domoves $*
    solve $REPLY
else
    while read -rep 'scramble: ' scramble; do
        REPLY=$SOLVED
        domoves $scramble
        solve $REPLY
    done
fi
