#!/usr/bin/env bash

# This file can be sourced or run independently to build the tables.

source ./defs.bash

echo generating tables...

# Runtime states use dense row numbers. Only the initial cube coordinate has
# to be translated from its sparse numeric representation; subsequent moves
# stay in the dense transition tables.
declare -iA tablesizes=(
    [co]=3**7
    [cp]=8*7*6*5*4*3*2
    [eo]=2**11
    [ep]=8*7*6*5*4*3*2
    [ud1]=12*11*10*9/4/3/2
    [ud2]=4*3*2
)

phase1moves=({F,B,L,R}{,\'} {F,B,R,L}2 {U,D}{,2,\'})
phase2moves=({U,D}{,2,\'} {F,B,L,R}2)

pad=${#tablesizes[@]} pad=${#pad}
printf %s\\n \
    '#!/usr/bin/env bash' \
    '# generated from gentables.bash' \
    'CUBE_TABLE_FORMAT=2' \
    'echo loading tables' \
    "pad=$pad" "ntable=0" > tables

# The caller supplies namerefs named index and trans. A row is assigned as soon
# as its coordinate is discovered, so q is both the BFS queue position and the
# dense state number. Transitions are stored row-major.
bfs () {
    local coord=$1 size=$2
    shift 2
    local allowed=("$@") nmoves=$#
    local queue=("$SOLVED") raw=("")
    local q=0 nextnum nextstate nextid mi m

    "$coord" $SOLVED
    raw[0]=$REPLY
    index[$REPLY]=0

    for ((;q<${#queue[@]};q++)); do
        verbose printf '\e7%s/%s\e8' "$q" "$size"
        for ((mi=0;mi<nmoves;mi++)); do
            m=${allowed[mi]}
            add ${queue[q]} ${moves[$m]}
            nextstate=$REPLY
            "$coord" $nextstate
            nextnum=$REPLY

            if [[ -v index[$nextnum] ]]; then
                nextid=${index[$nextnum]}
            else
                nextid=${#queue[@]}
                index[$nextnum]=$nextid
                raw[nextid]=$nextnum
                queue[nextid]=$nextstate
            fi
            trans[$((q*nmoves+mi))]=$nextid
        done
    done

    ((q==size)) || {
        printf 'internal error: %s has %s states, expected %s\n' "$coord" "$q" "$size" >&2
        return 1
    }
}

# cp co ep eo ud1 ud2 ep_
# $1 $2 $3 $4 $5  $6  $7
 cpcoord () { REPLY=$1; }
 cocoord () { REPLY=$2; }
 epcoord () { REPLY=$7; }
 eocoord () { REPLY=$4; }
ud1coord () { REPLY=$5; }
ud2coord () { REPLY=$6; }

ntable=0
buildtable () {
    local coord=$1 size=$2
    shift 2
    local allowed=("$@")

    declare -gA "${coord}index" "${coord}trans"
    local -n index="${coord}index" trans="${coord}trans"
    index=() trans=()

    printf '[%*s/%*s] %s transitions... ' "$pad" "$((++ntable))" "$pad" "${#tablesizes[@]}" "$coord"
    local t0=${EPOCHREALTIME/.} t1
    bfs "${coord}coord" "$size" "${allowed[@]}"

    {
        printf 'declare -A %sindex=(\n' "$coord"
        # Sorting gives reproducible, smaller gzip output.
        printf '%q %q\n' "${index[@]@k}" | sort -n
        printf ')\ndeclare -A %strans=(\n' "$coord"
        local i
        for ((i=0;i<${#trans[@]};i++)); do
            printf '%s %s ' "$i" "${trans[$i]}"
        done
        printf '\n)\n'
        printf '%s\n' "printf '[%*s/%*s] loaded %s transitions\\n' $pad \$((++ntable)) $pad ${#tablesizes[@]} $coord"
    } >>tables

    t1=${EPOCHREALTIME/.}
    showtime "$t0" "$t1" "$coord transitions"
}

for coord in co eo ud1; do
    buildtable "$coord" "${tablesizes[$coord]}" "${phase1moves[@]}"
done

for coord in cp ep ud2; do
    buildtable "$coord" "${tablesizes[$coord]}" "${phase2moves[@]}"
done

# Store 15 four-bit pruning distances in each positive signed 64-bit integer.
# Using all 16 nibbles would set the sign bit for some words.
emitpacked () {
    local name=$1 size=$2
    local i d word=0 shift=0 count=0

    printf 'declare -A %s=(\n' "$name" >>tables
    for ((i=0;i<size;i++)); do
        d=${prune[$i]}
        ((d>=0 && d<16)) || {
            printf 'internal error: %s[%s]=%s does not fit in a nibble\n' "$name" "$i" "$d" >&2
            return 1
        }
        ((word |= d<<shift, shift += 4, count++))
        if ((count==15)); then
            printf '%s %s ' "$((i/15))" "$word" >>tables
            word=0 shift=0 count=0
        fi
    done
    ((count==0)) || printf '%s %s ' "$((i/15))" "$word" >>tables
    printf '\n)\n' >>tables
}

# Build an exact distance table for a pair of coordinates. Individual
# transition tables are dense, so the product state is simply a*size_b+b.
buildprune () {
    local a=$1 b=$2 nmoves=$3
    local -n lefttrans="${a}trans" righttrans="${b}trans"
    local sizea=${tablesizes[$a]} sizeb=${tablesizes[$b]}
    local size=$((sizea*sizeb))
    local -A prune=([0]=0)
    local -a queue=([0]=0)
    local q=0 state sa sb anext bnext next mi distance max=0
    local name=${a}${b}prune

    printf '[%s/%s] %s pruning table... ' "$((++ntable))" 10 "$a+$b"
    local t0=${EPOCHREALTIME/.} t1

    for ((;q<${#queue[@]};q++)); do
        verbose printf '\e7%s/%s\e8' "$q" "$size"
        state=${queue[q]}
        distance=${prune[$state]}
        ((sa=state/sizeb, sb=state%sizeb, distance++))
        ((max=max<distance?distance:max))
        for ((mi=0;mi<nmoves;mi++)); do
            anext=${lefttrans[$((sa*nmoves+mi))]}
            bnext=${righttrans[$((sb*nmoves+mi))]}
            ((next=anext*sizeb+bnext))
            [[ -v prune[$next] ]] && continue
            prune[$next]=$distance
            queue+=("$next")
        done
    done

    ((q==size)) || {
        printf 'internal error: %s reached %s states, expected %s\n' "$name" "$q" "$size" >&2
        return 1
    }
    emitpacked "$name" "$size"
    printf '%s\n' "printf '[%s/%s] loaded %s pruning table\\n' \$((++ntable)) 10 $a+$b" >>tables

    t1=${EPOCHREALTIME/.}
    showtime "$t0" "$t1" "$a+$b prune (max $((max-1)))"
}

# These maps are already serialized and are not needed by the product BFSes.
unset coindex eoindex ud1index cpindex epindex ud2index

buildprune co ud1 "${#phase1moves[@]}"
buildprune eo ud1 "${#phase1moves[@]}"
buildprune cp ud2 "${#phase2moves[@]}"
buildprune ep ud2 "${#phase2moves[@]}"

echo echo loading complete >>tables
echo generation complete
