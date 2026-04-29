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
