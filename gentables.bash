#!/bin/bash

# this file can be sourced or ran indepenently to build the tables

source ./defs.bash

echo generating tables...
# the transition tables are in the form table[1234R]=5678
# the pruning tables are in the form prune[1234]=3
# all of them use ep_ and not ep
declare -A {{c,e}{o,p},ud{1,2}}{prune,trans}
declare -iA tablesizes=(
    [co]=3**7
    [cp]=8*7*6*5*4*3*2
    [eo]=2**11
    [ep]=8*7*6*5*4*3*2
    [ud1]=12*11*10*9/4/3/2
    [ud2]=4*3*2
)
pad=${#tablesizes[@]} pad=${#pad}
printf %s\\n \
    '#!/usr/bin/env bash' \
    '# generated from gentables.bash' \
    'echo loading tables' \
    "pad=$pad" "ntable=0" > tables

# bfs is used to build both the pruning tables and the transition tables
# the caller must define functions for coord and trans
# (which can be noops in the future for tables with no direct connection to coordinates)
# coord gets passed a cube representation
# trans gets passed a move, the current cube and the next cube
bfs () {
    local coord=$1 trans=$2 size=$3 allowed=("${@:4}")
    local queue=("$SOLVED") q
    local currnum nextnum nextstate
    "$coord" $SOLVED
    prune[$REPLY]=0

    for ((;q<${#queue[@]};q++)); do
        verbose printf '\e7%s/%s\e8' "$q" "$size"
        "$coord" ${queue[q]}
        currnum=$REPLY
        for m in "${allowed[@]}"; do
            add ${queue[q]} ${moves[$m]}
            nextstate=$REPLY
            "$coord" $nextstate
            nextnum=$REPLY
            "$trans" "$m" ${queue[q]} $nextstate
            [[ -v prune[$nextnum] ]] && continue
            queue+=("$nextstate")
            ((prune[$nextnum]=prune[$currnum]+1))
        done
    done
}

# cp co ep eo ud1 ud2 ep_
# $1 $2 $3 $4 $5  $6  $7
 cpcoord () { REPLY=$1; }
 cocoord () { REPLY=$2; }
 epcoord () { REPLY=$7; }
 eocoord () { REPLY=$4; }
ud1coord () { REPLY=$5; }
ud2coord () { REPLY=$6; }

# move cp co ep eo ud1 ud2 ep_ cp co  ep  eo  ud1 ud2 ep_
# $1   $2 $3 $4 $5 $6  $7  $8  $9 $10 $11 $12 $13 $14 $15
 cptrans () {  cptrans[$2$1]=$9; }
 cotrans () {  cotrans[$3$1]=${10}; }
 eptrans () {  eptrans[$8$1]=${15}; }
 eotrans () {  eotrans[$5$1]=${12}; }
ud1trans () { ud1trans[$6$1]=${13}; }
ud2trans () { ud2trans[$7$1]=${14}; }
 notrans () { :; }

ntable=0
buildtable () {
    printf '[%*s/%*s] %s table... ' "$pad" "$((++ntable))" "$pad" "${#tablesizes[@]}" "$1"
    declare -gn prune="$1prune" trans="$1trans"
    t0=${EPOCHREALTIME/.}
    bfs "$1coord" "$2trans" "$3" "${@:4}"
    {
        printf 'declare -A %sprune=(\n' "$1"
        # sort just to make the gzipped version smaller
        printf '%q %q\n' "${prune[@]@k}" | sort
        printf ') %strans=(\n' "$1"
        printf '%q %q\n' "${trans[@]@k}" | sort
        printf ')\n'
        printf '%s\n' "printf '[%*s/%*s] loaded %s\n' $pad \$((++ntable)) $pad ${#tablesizes[@]} $1"
    } >>tables
    t1=${EPOCHREALTIME/.}
    showtime "$t0" "$t1" "$1 table"
}

# todo: run the rest in parallel

for coord in co eo ud1; do
    buildtable "$coord" "$coord" "${tablesizes[$coord]}" {U,D,F,B,L,R}{,2,\'}
done

for coord in cp ep ud2; do
    buildtable "$coord" "$coord" "${tablesizes[$coord]}" {U,D}{,2,\'} {F,B,L,R}2
done

echo echo loading complete >> tables

echo generation complete

echo prune: \
     eo=${#eoprune[@]} co=${#coprune[@]} ud1=${#ud1prune[@]} \
     ep=${#epprune[@]} cp=${#cpprune[@]} ud2=${#ud2prune[@]}

echo trans: \
     eo=${#eotrans[@]} co=${#cotrans[@]} ud1=${#ud1trans[@]} \
     ep=${#eptrans[@]} cp=${#cptrans[@]} ud2=${#ud2trans[@]}
