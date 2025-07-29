https://github.com/user-attachments/assets/9a0ee7d7-60df-4fae-b78d-5393a390d56f

a kociemba 2phase solver in bash

it will recalculate the pruning tables if they're missing

this particular version uses some rather large tables (at least for bash's standards)

for now it finds an optimal solution for phase 1 and solves phase 2 from there

current "speed records" on my machine (on the superflip):
- phase 1: 1665865 states in 12.607 sec (132k/s)
- phase 2: 2467005 states in 24.887 sec (99k/s)
