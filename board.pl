% The  throne -> center cell in 11x11 board where the king starts
throne(5, 5).

% The corners that king must reach to -> win
corner(0, 0).
corner(0, 10).
corner(10, 0).
corner(10, 10).

% A cell is special -> is the throne or a corner
special_cell(R, C) :- throne(R, C).
special_cell(R, C) :- corner(R, C).


% Convert row & col to a single value index(ex: row 0 & col 0 -> index 0)
pos_to_index(Row, Col, Index) :-
    Index is Row * 11 + Col.

% Get piece position
get_piece(Board, Row, Col, Piece) :-
    pos_to_index(Row, Col, Index),
    nth0(Index, Board, Piece). % Starts at 0 ,search for that position in the list then -> give back the piece there

% Helper predicate that replaces the element with a new value 
% Base case: if index = 0 -> replace the head 
replace_at(0, [_|Tail], NewValue, [NewValue|Tail]). 

replace_at(Index, [H|T], Value, [H|T2]) :-
    Index > 0,
    Index1 is Index - 1,
    replace_at(Index1, T, Value, T2).

% put a piece at a given position (row and column) , then return the new updated board
set_piece(Board, Row, Col, Piece, NewBoard) :-
    pos_to_index(Row, Col, Index),
    replace_at(Index, Board, Piece, NewBoard).

setup_board(Board) :-
    Board = [
     % R0 
     empty,   empty,   empty,   attacker,attacker,attacker,attacker,attacker,empty,   empty,   empty,
     % R1
     empty,   empty,   empty,   empty,   empty,   attacker,empty,   empty,   empty,   empty,   empty,
     % R2
     empty,   empty,   empty,   empty,   empty,   empty,   empty,   empty,   empty,   empty,   empty,
     % R3
     attacker,empty,   empty,   empty,   empty,   defender,empty,   empty,   empty,   empty,   attacker,
     % R4
     attacker,empty,   empty,   empty,   defender,defender,defender,empty,   empty,   empty,   attacker,
     % R5 (center row with king)
     attacker,attacker,empty,   defender,defender,king,    defender,defender,empty,   attacker,attacker,
     % R6
     attacker,empty,   empty,   empty,   defender,defender,defender,empty,   empty,   empty,   attacker,
     % R7
     attacker,empty,   empty,   empty,   empty,   defender,empty,   empty,   empty,   empty,   attacker,
     % R8
     empty,   empty,   empty,   empty,   empty,   empty,   empty,   empty,   empty,   empty,   empty,
     % R9
     empty,   empty,   empty,   empty,   empty,   attacker,empty,   empty,   empty,   empty,   empty,
     % R10 
     empty,   empty,   empty,   attacker,attacker,attacker,attacker,attacker,empty,   empty,   empty
    ].


 % Print the board
print_board(Board) :-
    nl,
    write('   0  1  2  3  4  5  6  7  8  9  10'), nl,
    print_rows(Board, 0). % start from row 0


print_rows(_, 11) :- !. % stop when we reach row 11 

print_rows(Board, Row) :-
    Row < 11,
    (Row < 10 -> write(' '), write(Row), write('  ') ; write(Row), write('  ')),
    print_cols(Board, Row, 0), % Print all columns for this row 
    nl,
    NewRow is Row + 1,
    print_rows(Board, NewRow).
 
% Get the piece and its Role to print columns
print_cols(_, _, 11) :- !.  % stop when we reach column 11 

print_cols(Board, Row, Col) :-
    Col < 11,
    get_piece(Board, Row, Col, Piece),
    piece_role(Piece, Role),
    write(Role), write('   '), 
    NewCol is Col + 1,
    print_cols(Board, Row, NewCol).

% roles of poeces 
piece_role(king,     'K').
piece_role(attacker, 'A').
piece_role(defender, 'D').
piece_role(empty,    '.').

% A copy of the board
duplicate_board(Board, BoardCopy) :-
      copy_term(Board, BoardCopy). %  to try on 
