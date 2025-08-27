#!/usr/bin/env bash

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
    local lvl=$((lvl+1)) m next{0,1,2} sofar
    #verbose echo

    for m in "${allowed[@]}"; do
        #verbose printf '%*slvl=%s m=%s\e[K\r' "$lvl" '' "$lvl" "$sofar$m"
        [[ $m != [${badnext[$1]}]* ]] || continue
        #verbose sofar+="$m "
        #verbose ((ida++))
        ((lvl+${h0}prune[$((next0=${h0}trans[$2$m]))]<depth)) &&
        ((lvl+${h1}prune[$((next1=${h1}trans[$3$m]))]<depth)) &&
        ((lvl+${h2}prune[$((next2=${h2}trans[$4$m]))]<depth)) || continue

        stack[lvl]=$m
        ((next0^goal0|next1^goal1|next2^goal2)) || return 0
        idastar "$m" "$next0" "$next1" "$next2" && return
    done
    #verbose printf '\e[A\e[J'
    return 1
}

searchdepth () {
    local ida=0 t0 t1 state=$* depth=2 d e=1
    ((d=${h0}prune[$1],depth=depth<d?d:depth))
    ((d=${h1}prune[$2],depth=depth<d?d:depth))
    ((d=${h2}prune[$3],depth=depth<d?d:depth))
    for ((;e;depth++)) do
        echo "depth=$((depth-1))"
        t0=${EPOCHREALTIME/.}
        idastar Z $state; e=$?
        t1=${EPOCHREALTIME/.}
        showtime "$t0" "$t1"
    done
    #verbose printf '\e[32m%s\e[m states reached\n' "$ida"
}

simplify () {
    set -- "${@//\'/3}"
    set -- "${@/%[^23]/&1}"
    local join='(.*)(.)([123])\2([123])(.*)'
    local swap='(.*)((D.)(U.)|(L.)(R.)|(B.)(F.))(.*)'
    declare -n m=BASH_REMATCH
    local IFS=
    REPLY=$*
    while :; do
        if [[ $REPLY =~ $join ]]; then
            REPLY=${m[1]}${m[2]}$((m[3]+m[4]))${m[5]}
            REPLY=${REPLY//5/1}
            REPLY=${REPLY//6/2}
            REPLY=${REPLY//?4}
        elif [[ $REPLY =~ $swap ]]; then
            REPLY=${m[1]}
            if [[ ${m[3]} ]]; then
                REPLY+=${m[4]}${m[3]}
            elif [[ ${m[5]} ]]; then
                REPLY+=${m[6]}${m[5]}
            else
                REPLY+=${m[8]}${m[7]}
            fi
            REPLY+=${m[9]}
        else
            break
        fi
    done
    REPLY=${REPLY//[123]/& }
    REPLY=${REPLY//1}
    REPLY=${REPLY//3/\'}
}

# quickly check that the current phase isn't already solved
quickcheck () (($1^goal0|$2^goal1|$3^goal2))

domoves () for m do add $REPLY ${moves[$m]}; done

solve () {
    echo ===solving===
    toshow "$@"

    local depth state=($*) h allowed t stack=()
    local solved=($SOLVED) solution=()

    # each state is a tuple of (cp,co,ep,eo,ud1,ud2,ep_)
    # ep_ is ep for only the u and d layers

    printf '\e[32mphase 1\e[m\n'
    t[0]=${EPOCHREALTIME/.}
    phase1state=("${state[1]}" "${state[3]}" "${state[4]}")
    goal0=${solved[1]} goal1=${solved[3]} goal2=${solved[4]} # co eo ud1
    h0=co h1=eo h2=ud1
    allowed=({F,B,L,R}{,\'} {F,B,R,L}2 {U,D}{,2,\'})
    if quickcheck "${phase1state[@]}"; then
        searchdepth "${phase1state[@]}"
        solution=("${stack[@]}") stack=()

        # apply the solution we just found to know what the full state is
        REPLY=$*
        domoves "${solution[@]}"
        state=($REPLY)
    fi
    t[1]=${EPOCHREALTIME/.}

    printf '\e[32mphase 2\e[m\n'
    t[2]=${EPOCHREALTIME/.}
    phase2state=("${state[0]}" "${state[6]}" "${state[5]}") # restricted ep
    goal0=${solved[0]} goal1=${solved[6]} goal2=${solved[5]} # cp ep_ ud2
    h0=cp h1=ep h2=ud2
    allowed=({U,D}{,2,\'} {F,B,L,R}2)
    if quickcheck "${phase2state[@]}"; then
        searchdepth "${phase2state[@]}"
        solution+=("${stack[@]}")
    fi
    t[3]=${EPOCHREALTIME/.}

    simplify "${solution[@]}"
    solution=($REPLY)

    showtime "${t[0]}" "${t[1]}" phase1
    showtime "${t[2]}" "${t[3]}" phase2
    printf 'solution: \e[32m%s\e[m (\e[32m%s\e[m HTM)\e[m\n' "${solution[*]}" "${#solution[@]}"
}

if (( $# )); then
    echo scramble: "$@"
    REPLY=$SOLVED
    if [[ $1 = --reid ]]; then
        shift
        reid $*
    else
        domoves $*
    fi
    solve $REPLY
else
    set -o emacs
    bind tab:
    while IFS= read -rep 'scramble: ' scramble; do
        [[ $scramble =~ ^' '*$ ]] && continue
        history -s -- "$scramble"

        scramble=($scramble)
        if [[ ${scramble[0]} = --reid ]]; then
            reid ${scramble[@]:1}
        else
            regex="^ *([UDFBRL][2']? +)*[UDFBRL][2']? *$"
            [[ ${scramble[@]} =~ $regex ]] || { echo invalid scramble; continue; }
            REPLY=$SOLVED
            domoves ${scramble[@]}
        fi
        solve $REPLY
    done
fi
