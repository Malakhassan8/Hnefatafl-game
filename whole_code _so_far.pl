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

%%%  Move Generation & Applying Moves %%%

% maps each piece to its side
%piece_belongs_to(Piece, Side).

piece_belongs_to(attacker, attacker).
piece_belongs_to(defender, defender).
piece_belongs_to(king, defender).



% collect every possible move for a given side into a list 

valid_moves(Board , Side , List_of_moves):-
    findall( 
        move(FR,FC,TR,TC),      %What to collect
        (   
           between(0,10,FR),                    
           between(0,10,FC),   
           get_piece(Board, FR, FC, Piece),
           piece_belongs_to(Piece,Side),   %Conditions
           between(0,10,TR),                   
           between(0,10,TC),                     
           can_slide(Board,FR,FC,TR,TC)
        ),
        List_of_moves
        ).



% can_slide(Board, FromRow, FromCol, ToRow, ToCol)
% True if a piece can legally slide from (FR,FC) to (TR,TC)

% Horizontal move
can_slide(Board,FR,FC,FR,TC):-
    FC =\= TC,    % must move
    get_piece(Board, FR, TC, empty),    % Forces destination to be empty
    \+ (special_cell(FR, TC), \+ get_piece(Board, FR, FC, king)),    
    clear_horizontal_path(Board, FR, FC, TC).  % Nothing blocking the path


% Vertical move
can_slide(Board,FR,FC,TR,FC):-
    FR =\= TR ,   % must move
    get_piece(Board, TR, FC, empty),    % Forces destination to be empty
    \+ (special_cell(TR, FC), \+ get_piece(Board, FR, FC, king)),    
   clear_vertical_path(Board, FC, FR, TR).  % Nothing blocking the path



%clear_horizontal_path(Board, Row, FromCol, ToCol)
% Checks all squares BETWEEN FromCol and ToCol on the same row
% are empty (does not check the destination itself)

clear_horizontal_path(Board,Row,FC,TC):-
    FC < TC,    %moving right
    Mid is FC + 1,
    all_empty_cols(Board,Row,Mid,TC).
    
    
clear_horizontal_path(Board,Row,FC,TC):-
    FC > TC,     %moving left
    Mid is TC + 1,
    all_empty_cols(Board,Row,Mid,FC).


all_empty_cols(_,_,Limit,Limit):- !. %Base case

all_empty_cols(Board,Row,C,Limit):-  % Recursive case
    C < Limit,
    get_piece(Board, Row,C , empty),
    Next is C + 1,
    all_empty_cols(Board,Row,Next,Limit).
    

   


% clear_vertical_path(Board, Col, FromCol, ToCol)
% Checks all squares BETWEEN FromRow and ToRow on the same col
% are empty (does not check the destination itself)


clear_vertical_path(Board,Col,FR,TR):-
    FR < TR ,
    Mid is FR + 1,
    all_empty_rows(Board,Col,Mid,TR).



clear_vertical_path(Board,Col,FR,TR):-
      FR > TR ,
    Mid is TR + 1,
    all_empty_rows(Board,Col,Mid,FR).


    
all_empty_rows(_,_,Limit,Limit):- !.  % Base case

all_empty_rows(Board,Col,R,Limit):-  % Recursive case
    R < Limit ,
    get_piece(Board,R , Col , empty),
    Next is R + 1,
    all_empty_rows(Board,Col,Next,Limit).

% apply_move(Board, Move, NewBoard)
% Executes a move on the board and returns the updated board
apply_move(Board, move(FR, FC, TR, TC), NewBoard) :-
    get_piece(Board, FR, FC, Piece),
    set_piece(Board, FR, FC, empty, Tmp),
    set_piece(Tmp, TR, TC, Piece, NewBoard).

    
% =====================================================================
CAPTURE LOGIC & END-OF-GAME DETECTION
% =====================================================================

% ---------------------------------------------------------------------
% King is unarmed -> cannot help in capturing
% ---------------------------------------------------------------------
is_unarmed(king).


% ---------------------------------------------------------------------
% enemy_piece(Side, Piece)
% True if Piece belongs to the opposite side of Side
% ---------------------------------------------------------------------
enemy_piece(attacker, defender).
enemy_piece(attacker, king).
enemy_piece(defender, attacker).


% ---------------------------------------------------------------------
% ally_for_capture(Side, Row, Col, Board)
% ---------------------------------------------------------------------
ally_for_capture(_, R, C, _) :-
    corner(R, C), !.

ally_for_capture(_, R, C, Board) :-
    throne(R, C),
    get_piece(Board, R, C, Piece),
    Piece \= king, !.   % empty throne (or throne after king leaves) supports capture

ally_for_capture(Side, R, C, Board) :-
    R >= 0, R =< 10,
    C >= 0, C =< 10,
    get_piece(Board, R, C, Piece),
    piece_belongs_to(Piece, Side),
    \+ is_unarmed(Piece).


% ---------------------------------------------------------------------
% apply_captures(Board, LastMove, Side, NewBoard)
% ---------------------------------------------------------------------
apply_captures(Board, move(_, _, TR, TC), Side, NewBoard) :-
    % four directions: up, down, left, right
    try_capture(Board,  Side, TR, TC, -1,  0, B1),
    try_capture(B1,     Side, TR, TC,  1,  0, B2),
    try_capture(B2,     Side, TR, TC,  0, -1, B3),
    try_capture(B3,     Side, TR, TC,  0,  1, NewBoard).


% try_capture(Board, Side, FromR, FromC, DR, DC, NewBoard)

try_capture(Board, Side, R, C, DR, DC, NewBoard) :-
    NR  is R  + DR,  NC  is C  + DC,    % neighbor
    NR2 is NR + DR,  NC2 is NC + DC,    % square beyond neighbor
    NR  >= 0, NR  =< 10, NC  >= 0, NC  =< 10,
    NR2 >= 0, NR2 =< 10, NC2 >= 0, NC2 =< 10,
    get_piece(Board, NR, NC, EnemyPiece),
    enemy_piece(Side, EnemyPiece),
    EnemyPiece \= king,                 % king has its own capture rules
    ally_for_capture(Side, NR2, NC2, Board), !,
    set_piece(Board, NR, NC, empty, NewBoard).

% Otherwise, no capture in this direction
try_capture(Board, _, _, _, _, _, Board).


% ---------------------------------------------------------------------
% find_king(Board, KR, KC)
% Locate the kings current position
% ---------------------------------------------------------------------
find_king(Board, KR, KC) :-
    between(0, 10, KR),
    between(0, 10, KC),
    get_piece(Board, KR, KC, king), !.


% ---------------------------------------------------------------------
% king_escaped(Board)
% True if the king is currently on any corner square -> defenders win
% ---------------------------------------------------------------------
king_escaped(Board) :-
    find_king(Board, KR, KC),
    corner(KR, KC).



king_captured(Board) :-
    find_king(Board, KR, KC),
    \+ corner(KR, KC),                  % escaping king is not captured
    king_surrounded(Board, KR, KC).


% king_surrounded/3
% Check that all 4 cardinal neighbors are hostile (attacker / throne / corner / off-board edge handling)
king_surrounded(Board, KR, KC) :-
    hostile_to_king(Board, KR, KC, -1,  0),
    hostile_to_king(Board, KR, KC,  1,  0),
    hostile_to_king(Board, KR, KC,  0, -1),
    hostile_to_king(Board, KR, KC,  0,  1).


% hostile_to_king(Board, KR, KC, DR, DC)


hostile_to_king(_, KR, KC, DR, DC) :-
    NR is KR + DR, NC is KC + DC,
    ( NR < 0 ; NR > 10 ; NC < 0 ; NC > 10 ), !.   % off-board = wall

hostile_to_king(_, KR, KC, DR, DC) :-
    NR is KR + DR, NC is KC + DC,
    corner(NR, NC), !.

hostile_to_king(Board, KR, KC, DR, DC) :-
    NR is KR + DR, NC is KC + DC,
    throne(NR, NC),
    get_piece(Board, NR, NC, Piece),
    Piece \= king, !.                              % empty throne is hostile

hostile_to_king(Board, KR, KC, DR, DC) :-
    NR is KR + DR, NC is KC + DC,
    get_piece(Board, NR, NC, attacker).


% ---------------------------------------------------------------------
% game_over(Board, Winner)

game_over(Board, defender) :-
    king_escaped(Board), !.

game_over(Board, attacker) :-
    king_captured(Board), !.

game_over(Board, attacker) :-
    valid_moves(Board, defender, []), !.   % defender has no legal move

game_over(Board, defender) :-
    valid_moves(Board, attacker, []), !.   % attacker has no legal move


% ---------------------------------------------------------------------
% make_move(Board, Move, Side, NewBoard)

make_move(Board, Move, Side, NewBoard) :-
    apply_move(Board, Move, TempBoard),
    apply_captures(TempBoard, Move, Side, NewBoard).


    
      
