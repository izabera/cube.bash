#!/usr/bin/env bash

source ./defs.bash
source ./ui.bash

# The ignored `tables` file is a decompression cache. Refresh an old-format
# cache automatically after upgrading the checked-in tables.gz.
if [[ ! -e tables ]] || ! grep -qx 'CUBE_TABLE_FORMAT=2' tables; then
    [[ -e tables.gz ]] && gunzip < tables.gz > tables
    grep -qx 'CUBE_TABLE_FORMAT=2' tables 2>/dev/null || source ./gentables.bash
fi
source ./tables

# Move faces are F B L R U D = 0..5, with 6 used at the root.  Precomputing
# legal move indices avoids a glob match (and skipped loop iterations) at every
# node. Opposite faces retain the canonical order F B, R L, and U D.
declare -a moveface1=(0 0 1 1 2 2 3 3 0 1 3 2 4 4 4 5 5 5)
declare -a legal1=(
    '2 3 4 5 6 7 9 10 11 12 13 14 15 16 17'
    '4 5 6 7 10 11 12 13 14 15 16 17'
    '0 1 2 3 8 9 12 13 14 15 16 17'
    '0 1 2 3 4 5 8 9 11 12 13 14 15 16 17'
    '0 1 2 3 4 5 6 7 8 9 10 11 15 16 17'
    '0 1 2 3 4 5 6 7 8 9 10 11'
    '0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17'
)
declare -a moveface2=(4 4 4 5 5 5 0 1 2 3)
declare -a legal2=(
    '0 1 2 3 4 5 7 8 9'
    '0 1 2 3 4 5 8 9'
    '0 1 2 3 4 5 6 7'
    '0 1 2 3 4 5 6 7 8'
    '3 4 5 6 7 8 9'
    '6 7 8 9'
    '0 1 2 3 4 5 6 7 8 9'
)

# Phase 1 uses exact co+ud1 and eo+ud1 pattern databases.  Transition states
# are dense row numbers; each pruning word packs 15 four-bit distances.
idastar1 () {
    local lvl=$((lvl+1)) mi next{0,1,2} p word sofar
    local s0=$2 s1=$3 s2=$4
    verbose echo

    for mi in ${legal1[$1]}; do
        verbose printf '%*slvl=%s m=%s\e[K\r' "$lvl" '' "$lvl" "$sofar${allowed[mi]}"
        verbose sofar+="${allowed[mi]} "
        verbose ((ida++))

        # ud1 is shared by both patterns. Check co+ud1 before paying for eo.
        next2=${ud1trans[$((s2*18+mi))]}
        next0=${cotrans[$((s0*18+mi))]}
        ((p=next0*495+next2))
        word=${coud1prune[$((p/15))]}
        ((lvl+(word>>(p%15*4)&15)<depth)) || continue
        next1=${eotrans[$((s1*18+mi))]}
        ((p=next1*495+next2))
        word=${eoud1prune[$((p/15))]}
        ((lvl+(word>>(p%15*4)&15)<depth)) || continue

        stack[lvl]=${allowed[mi]}
        ((next0|next1|next2)) || return 0
        idastar1 "${moveface1[mi]}" "$next0" "$next1" "$next2" && return
    done
    verbose printf '\e[A\e[J'
    return 1
}

# Phase 2 is the same search over cp+ud2 and ep+ud2 pattern databases.
idastar2 () {
    local lvl=$((lvl+1)) mi next{0,1,2} p word sofar
    local s0=$2 s1=$3 s2=$4
    verbose echo

    for mi in ${legal2[$1]}; do
        verbose printf '%*slvl=%s m=%s\e[K\r' "$lvl" '' "$lvl" "$sofar${allowed[mi]}"
        verbose sofar+="${allowed[mi]} "
        verbose ((ida++))

        # ud2 is shared by both patterns. Check cp+ud2 before paying for ep.
        next2=${ud2trans[$((s2*10+mi))]}
        next0=${cptrans[$((s0*10+mi))]}
        ((p=next0*24+next2))
        word=${cpud2prune[$((p/15))]}
        ((lvl+(word>>(p%15*4)&15)<depth)) || continue
        next1=${eptrans[$((s1*10+mi))]}
        ((p=next1*24+next2))
        word=${epud2prune[$((p/15))]}
        ((lvl+(word>>(p%15*4)&15)<depth)) || continue

        stack[lvl]=${allowed[mi]}
        ((next0|next1|next2)) || return 0
        idastar2 "${moveface2[mi]}" "$next0" "$next1" "$next2" && return
    done
    verbose printf '\e[A\e[J'
    return 1
}

searchdepth () {
    local searchfn=$1
    shift
    local ida=0 t0 t1 state=("$@") depth d e=1 p word

    if [[ $searchfn = idastar1 ]]; then
        ((p=$1*495+$3))
        word=${coud1prune[$((p/15))]}
        ((depth=word>>(p%15*4)&15, p=$2*495+$3))
        word=${eoud1prune[$((p/15))]}
        ((d=word>>(p%15*4)&15))
    else
        ((p=$1*24+$3))
        word=${cpud2prune[$((p/15))]}
        ((depth=word>>(p%15*4)&15, p=$2*24+$3))
        word=${epud2prune[$((p/15))]}
        ((d=word>>(p%15*4)&15))
    fi
    ((depth=depth<d?d:depth, depth++))

    for ((;e;depth++)) do
        echo "depth=$((depth-1))"
        t0=${EPOCHREALTIME/.}
        "$searchfn" 6 "${state[@]}"; e=$?
        t1=${EPOCHREALTIME/.}
        showtime "$t0" "$t1"
    done
    verbose printf '\e[32m%s\e[m states reached\n' "$ida"
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

# Dense coordinate zero is the solved row for every table.
quickcheck () (($1|$2|$3))

domoves () for m do add $REPLY ${moves[$m]}; done

solve () {
    echo ===solving===
    toshow "$@"

    local depth state=($*) allowed t stack=() solution=()

    # each state is a tuple of (cp,co,ep,eo,ud1,ud2,ep_)
    # ep_ is ep for only the u and d layers

    printf '\e[32mphase 1\e[m\n'
    t[0]=${EPOCHREALTIME/.}
    phase1state=(
        "${coindex[${state[1]}]}"
        "${eoindex[${state[3]}]}"
        "${ud1index[${state[4]}]}"
    )
    allowed=({F,B,L,R}{,\'} {F,B,R,L}2 {U,D}{,2,\'})
    if quickcheck "${phase1state[@]}"; then
        searchdepth idastar1 "${phase1state[@]}"
        solution=("${stack[@]}") stack=()

        # apply the solution we just found to know what the full state is
        REPLY=$*
        domoves "${solution[@]}"
        state=($REPLY)
    fi
    t[1]=${EPOCHREALTIME/.}

    printf '\e[32mphase 2\e[m\n'
    t[2]=${EPOCHREALTIME/.}
    phase2state=(
        "${cpindex[${state[0]}]}"
        "${epindex[${state[6]}]}"
        "${ud2index[${state[5]}]}"
    ) # restricted ep
    allowed=({U,D}{,2,\'} {F,B,L,R}2)
    if quickcheck "${phase2state[@]}"; then
        searchdepth idastar2 "${phase2state[@]}"
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
