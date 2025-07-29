#!/usr/bin/env bash

LANG=C
set -f

[[ $VERBOSE ]] && alias verbose= || alias verbose=#
shopt -s expand_aliases

showtime () {
    local t=$(($2-$1))
    printf '\r%s%s.%03ds\e[m\e[K\n' "${3+$3:$' \e[32m'}" "$((t/1000000))" "$(((t%1000000)/1000))"
}

# cubies are stored in speffz order
# while building the tables, cubes are represented as co cp eo ep ud1 ud2 ep_
# ep also encodes ud1/ud2, ep_ is restricted to top and bottom
# the values in all tables are also different from how kociemba is normally implemented
# but what matters is that they uniquely identify each state
# all our tables are going to be sparse and funny-looking anyway

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
    local i c {c,e}{p,o} ep_ ud{1,2}
    for ((;i<$#;i++)) do
        c=${cubies[${@:i+1:1}]}
        if ((i<8)); then
            ((cp=cp*8+c/3, co=co*3+c%3))
        else
            ((c-=24))
            ((ep=ep*12+c/2, eo=eo*2+c%2))
            ((ud1=ud1*2+(c>=8&&c<16), ud2=ud2*12+(c>=8&&c<16?c/2:0) ))
            ((ep_=ep_*12+(c<8||c>=16)*c/2))
        fi
    done
    REPLY="$cp $co $ep $eo $ud1 $ud2 $ep_"
}

declare -A moves

cube ULB URB URF ULF   DLF DRF DRB DLB   UB UR UF UL   BL FL FR BR   DF DR DB DL; SOLVED=$REPLY
cube UFL UBL UBR UFR   DLF DRF DRB DLB   UL UB UR UF   BL FL FR BR   DF DR DB DL; moves[U]=$REPLY
cube ULB URB URF ULF   DLB DLF DRF DRB   UB UR UF UL   BL FL FR BR   DL DF DR DB; moves[D]=$REPLY
cube ULB FRU FRD ULF   DLF BRD BRU DLB   UB FR UF UL   BL FL DR UR   DF BR DB DL; moves[R]=$REPLY
cube BLD URB URF BLU   FLU DRF DRB FLD   UB UR UF BL   DL UL FR BR   DF DR DB FL; moves[L]=$REPLY
cube ULB URB LFU LFD   RFD RFU DRB DLB   UB UR LF UL   BL FD FU BR   RF DR DB DL; moves[F]=$REPLY
cube RBU RBD URF ULF   DLF DRF LDB LBU   RB UR UF UL   BU FL FR BD   DF DR LB DL; moves[B]=$REPLY

# cp co ep eo ud1 ud2 ep_ cp co ep eo ud1 ud2 ep_
# 0  1  2  3  4   5   6   7  8  9  10 11  12  13
add () {
    local {lhs,rhs,}{c,e}{p,o} ep_ ud{1,2} i args=("$@")
    for ((i=0;i<8;i++)) do
        ((lhscp[7-i]=args[0]%8, args[0]/=8, lhsco[7-i]=args[1]%3, args[1]/=3))
        ((rhscp[7-i]=args[7]%8, args[7]/=8, rhsco[7-i]=args[8]%3, args[8]/=3))
    done
    for ((i=0;i<12;i++)) do
        ((lhsep[11-i]=args[2]%12, args[2]/=12, lhseo[11-i]=args[3]%2, args[3]/=2))
        ((rhsep[11-i]=args[9]%12, args[9]/=12, rhseo[11-i]=args[10]%2, args[10]/=2))
    done

    for ((i=0;i<8;i++)) do
        ((cp=cp*8+lhscp[rhscp[i]], co=co*3+(lhsco[rhscp[i]]+rhsco[i])%3))
    done
    for ((i=0;i<12;i++)) do
        ((ep=ep*12+lhsep[rhsep[i]], eo=eo*2+(lhseo[rhsep[i]]+rhseo[i])%2))
        ((ud1=ud1*2+(ep%12>=4&&ep%12<8), ud2=ud2*12+(ep%12>=4&&ep%12<8?ep%12:0) ))
        ((ep_=ep_*12+(ep%12<4||ep%12>=8)*ep%12))
    done

    REPLY="$cp $co $ep $eo $ud1 $ud2 $ep_"
}

for m in U D F B R L; do
    add ${moves[$m]} ${moves[$m]};   moves[$m\2]=$REPLY
    add ${moves[$m]} ${moves[$m\2]}; moves[$m\']=$REPLY
done
