
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

%----------- fixed -----------
% Horizontal move
% Fixed: special_cell check now correctly reads the piece from the source square
% instead of calling get_piece as a boolean test
can_slide(Board,FR,FC,FR,TC):-
    FC =\= TC,    % must move
    get_piece(Board, FR, TC, empty),    % Forces destination to be empty
    get_piece(Board, FR, FC, Piece),
    \+ (special_cell(FR, TC), Piece \= king),
    clear_horizontal_path(Board, FR, FC, TC).  % Nothing blocking the path

%----------- fixed -----------
% Vertical move
% Fixed: special_cell check now correctly reads the piece from the source square
% instead of calling get_piece as a boolean test
can_slide(Board,FR,FC,TR,FC):-
    FR =\= TR ,   % must move
    get_piece(Board, TR, FC, empty),    % Forces destination to be empty
    get_piece(Board, FR, FC, Piece),
    \+ (special_cell(TR, FC), Piece \= king),
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
%CAPTURE LOGIC & END-OF-GAME DETECTION
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


%----------- fixed -----------
% king_captured(Board)
% Fixed: now correctly handles 3 cases per the assignment rules:
%   1. King in open board -> all 4 sides must be hostile
%   2. King against a wall (edge) -> 3 sides hostile (wall counts as 1)
%   3. King at a corner -> 2 sides hostile (2 walls count as 2)
% The previous king_surrounded treated off-board as hostile in all cases,
% which was correct for walls but did NOT short-circuit for the corner case.
% Now king_surrounded_dynamic counts required hostile neighbors correctly.

king_captured(Board) :-
    find_king(Board, KR, KC),
    \+ corner(KR, KC),                  % escaping king is not captured
    king_surrounded_dynamic(Board, KR, KC).

% king_surrounded_dynamic/3
% Counts how many of the 4 directions are hostile (including off-board walls),
% then checks that ALL 4 directions are effectively blocked.
% This naturally satisfies:
%   - open board: needs 4 attacker/throne/corner neighbors
%   - edge: 1 off-board wall + 3 others
%   - near-corner: 2 off-board walls + 2 others
king_surrounded_dynamic(Board, KR, KC) :-
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



% ---------------------------------------------------------------------
% Difficulty levels -> search depth
% ---------------------------------------------------------------------
difficulty_depth(easy,   1).
difficulty_depth(medium, 2).
difficulty_depth(hard,   3).


% =====================================================================
% HEURISTIC / UTILITY
% =====================================================================

% ---------------------------------------------------------------------
% count_pieces(+Board, +Side, -Count)
% Count how many pieces belong to Side on the board
% ---------------------------------------------------------------------
count_pieces(Board, Side, Count) :-
    findall(1, (
        between(0, 10, R),
        between(0, 10, C),
        get_piece(Board, R, C, Piece),
        piece_belongs_to(Piece, Side)
    ), Ones),
    length(Ones, Count).


% ---------------------------------------------------------------------
% manhattan_to_nearest_corner(+KR, +KC, -Dist)
% Minimum Manhattan distance from (KR,KC) to any of the 4 corners
% ---------------------------------------------------------------------
manhattan_to_nearest_corner(KR, KC, Dist) :-
    findall(D, (
        corner(CR, CC),
        D is abs(KR - CR) + abs(KC - CC)
    ), Ds),
    min_list(Ds, Dist).


% ---------------------------------------------------------------------
% king_legal_moves_count(+Board, -Count)
% Number of squares the king can legally slide to
% ---------------------------------------------------------------------
king_legal_moves_count(Board, Count) :-
    find_king(Board, KR, KC),
    findall(1, (
        between(0, 10, TR),
        between(0, 10, TC),
        can_slide(Board, KR, KC, TR, TC)
    ), Ones),
    length(Ones, Count).


% ---------------------------------------------------------------------
% attackers_adjacent_to_king(+Board, -Count)
% Number of attackers in the 4 orthogonal squares next to the king
% ---------------------------------------------------------------------
attackers_adjacent_to_king(Board, Count) :-
    find_king(Board, KR, KC),
    findall(1, (
        member((DR, DC), [(-1,0),(1,0),(0,-1),(0,1)]),
        NR is KR + DR,
        NC is KC + DC,
        NR >= 0, NR =< 10,
        NC >= 0, NC =< 10,
        get_piece(Board, NR, NC, attacker)
    ), Ones),
    length(Ones, Count).


% ---------------------------------------------------------------------
% evaluate(+Board, +Side, -Score)
%
% Positive score = good for Side.
%
% Components (all from the DEFENDER's perspective, then flipped for attacker):
%   1. Piece count difference  (defenders - attackers), weighted
%   2. King Manhattan distance  (smaller = better for defender)
%   3. King mobility            (more moves = better for defender)
%   4. Threat level             (more adjacent attackers = worse for defender)
% ---------------------------------------------------------------------
evaluate(Board, Side, Score) :-
    % --- Terminal states (highest/lowest possible scores) ---
    ( king_escaped(Board)  -> RawScore =  100000
    ; king_captured(Board) -> RawScore = -100000
    ; valid_moves(Board, defender, []) -> RawScore = -100000
    ; valid_moves(Board, attacker, []) -> RawScore =  100000
    ;
        % 1. Piece counts
        count_pieces(Board, attacker, AtkCount),
        count_pieces(Board, defender, DefCount),
        PieceDiff is DefCount * 10 - AtkCount * 5,

        % 2. King distance to nearest corner (smaller = better for defender)
        find_king(Board, KR, KC),
        manhattan_to_nearest_corner(KR, KC, CornerDist),
        DistScore is -CornerDist * 8,           % defender wants small distance

        % 3. King mobility
        king_legal_moves_count(Board, KingMoves),
        MobilityScore is KingMoves * 4,

        % 4. Threat level
        attackers_adjacent_to_king(Board, Threats),
        ThreatScore is -Threats * 15,

        RawScore is PieceDiff + DistScore + MobilityScore + ThreatScore
    ),
    % Flip sign if we are evaluating from the attacker's perspective
    ( Side = attacker -> Score is -RawScore ; Score = RawScore ).


% =====================================================================
% ALPHA-BETA PRUNING
% =====================================================================

% ---------------------------------------------------------------------
% alpha_beta(+Board, +Depth, +Alpha, +Beta, +Side, -BestMove, -Score)
%
% Side      : whose turn it is right now (attacker | defender)
% BestMove  : best move found (unbound / 'none' at leaf / terminal)
% Score     : minimax score for Side
% ---------------------------------------------------------------------

% --- Terminal: depth 0 or game over ---
alpha_beta(Board, 0, _Alpha, _Beta, Side, none, Score) :-
    !,
    evaluate(Board, Side, Score).

alpha_beta(Board, _Depth, _Alpha, _Beta, Side, none, Score) :-
    game_over(Board, _Winner),
    !,
    evaluate(Board, Side, Score).

% --- Recursive case ---
alpha_beta(Board, Depth, Alpha, Beta, Side, BestMove, BestScore) :-
    valid_moves(Board, Side, Moves),
    Moves \= [],
    opposite_side(Side, OppSide),
    NewDepth is Depth - 1,
    ab_loop(Board, Moves, NewDepth, Alpha, Beta, Side, OppSide,
            none, Alpha, BestMove, BestScore).

% No moves available (shouldn't normally reach here if game_over is correct)
alpha_beta(Board, _Depth, _Alpha, _Beta, Side, none, Score) :-
    evaluate(Board, Side, Score).


% ---------------------------------------------------------------------
% opposite_side(?Side, ?Opp)
% ---------------------------------------------------------------------
opposite_side(attacker, defender).
opposite_side(defender, attacker).


% ---------------------------------------------------------------------
% ab_loop(+Board, +Moves, +Depth, +Alpha, +Beta,
%         +Side, +OppSide,
%         +CurrentBestMove, +CurrentBestScore,
%         -BestMove, -BestScore)
%
% Iterates over the move list, updating alpha and pruning when possible.
% ---------------------------------------------------------------------

% Base case: no moves left
ab_loop(_Board, [], _Depth, _Alpha, _Beta, _Side, _OppSide,
        BestMove, BestScore, BestMove, BestScore).

% Recursive case
ab_loop(Board, [Move|Rest], Depth, Alpha, Beta, Side, OppSide,
        CurBestMove, CurBestScore, BestMove, BestScore) :-

    % Apply the move (including captures)
    make_move(Board, Move, Side, NewBoard),

    % Recurse for opponent (negate score: opponent maximises from their view)
    alpha_beta(NewBoard, Depth, -Beta, -Alpha, OppSide, _, OppScore),
    Score is -OppScore,

    % Update best move and alpha
    ( Score > CurBestScore ->
        NewBestMove  = Move,
        NewBestScore = Score
    ;
        NewBestMove  = CurBestMove,
        NewBestScore = CurBestScore
    ),

    NewAlpha is max(Alpha, NewBestScore),

    % Beta cut-off (pruning)
    ( NewAlpha >= Beta ->
        BestMove  = NewBestMove,
        BestScore = NewBestScore          % prune remaining siblings
    ;
        ab_loop(Board, Rest, Depth, NewAlpha, Beta, Side, OppSide,
                NewBestMove, NewBestScore, BestMove, BestScore)
    ).


% =====================================================================
% PUBLIC INTERFACE
% =====================================================================

% ---------------------------------------------------------------------
% best_move(+Board, +Side, +Difficulty, -BestMove)
%
% Top-level predicate the game controller calls to get the computer move.
%   Difficulty : easy | medium | hard
% ---------------------------------------------------------------------
best_move(Board, Side, Difficulty, BestMove) :-
    difficulty_depth(Difficulty, Depth),
    alpha_beta(Board, Depth, -1000000, 1000000, Side, BestMove, _Score).


% =====================================================================
%----------- fixed -----------
% GAME CONTROLLER
% Added the missing game controller as required by the assignment.
% Handles: turn switching, human input, computer moves,
%          board printing after each move, and end-of-game declaration.
% =====================================================================

% ---------------------------------------------------------------------
% play/0
% Entry point -> sets up the board, asks for difficulty and human side,
% then starts the game loop (attacker always moves first per rules).
% ---------------------------------------------------------------------
play :-
    setup_board(Board),
    nl, write('=== Welcome to Hnefatafl (Viking Chess) ==='), nl,
    write('Attacker moves first.'), nl,
    nl,
    write('Choose difficulty: easy / medium / hard'), nl,
    write('Enter difficulty: '),
    read(Difficulty),
    ( difficulty_depth(Difficulty, _) -> true
    ;
        write('Invalid difficulty. Defaulting to medium.'), nl,
        Difficulty = medium
    ),
    nl,
    write('Choose your side: attacker / defender'), nl,
    write('Enter side: '),
    read(HumanSide),
    ( member(HumanSide, [attacker, defender]) -> true
    ;
        write('Invalid side. Defaulting to defender.'), nl,
        HumanSide = defender
    ),
    nl,
    print_board(Board),
    game_loop(Board, attacker, HumanSide, Difficulty).


% ---------------------------------------------------------------------
% game_loop(+Board, +CurrentSide, +HumanSide, +Difficulty)
% Switches turns between human and computer until the game is over.
% ---------------------------------------------------------------------
game_loop(Board, CurrentSide, HumanSide, Difficulty) :-
    % Check if game is already over before taking a turn
    ( game_over(Board, Winner) ->
        nl,
        format("=== Game Over! Winner: ~w ===~n", [Winner])
    ;
        ( CurrentSide = HumanSide ->
            human_turn(Board, CurrentSide, NewBoard)
        ;
            computer_turn(Board, CurrentSide, Difficulty, NewBoard)
        ),
        nl,
        print_board(NewBoard),
        % Check for game over after the move
        ( game_over(NewBoard, Winner2) ->
            nl,
            format("=== Game Over! Winner: ~w ===~n", [Winner2])
        ;
            opposite_side(CurrentSide, NextSide),
            game_loop(NewBoard, NextSide, HumanSide, Difficulty)
        )
    ).


% ---------------------------------------------------------------------
% human_turn(+Board, +Side, -NewBoard)
% Prompts the human player to enter a move, validates it, then applies it.
% Move format: move(FromRow, FromCol, ToRow, ToCol)
% Example input: move(5,3,5,0).
% ---------------------------------------------------------------------
human_turn(Board, Side, NewBoard) :-
    nl,
    format("Your turn (~w). Enter move as: move(FR,FC,TR,TC).~n", [Side]),
    read(Move),
    ( Move = move(FR, FC, TR, TC),
      valid_moves(Board, Side, ValidMoves),
      member(move(FR,FC,TR,TC), ValidMoves) ->
        make_move(Board, Move, Side, NewBoard),
        format("Move applied: ~w~n", [Move])
    ;
        write('Invalid move. Please try again.'), nl,
        human_turn(Board, Side, NewBoard)
    ).


% ---------------------------------------------------------------------
% computer_turn(+Board, +Side, +Difficulty, -NewBoard)
% Computes the best move using alpha-beta pruning and applies it.
% ---------------------------------------------------------------------
computer_turn(Board, Side, Difficulty, NewBoard) :-
    nl,
    format("Computer (~w) is thinking...~n", [Side]),
    best_move(Board, Side, Difficulty, BestMove),
    ( BestMove = none ->
        write('Computer has no valid moves.'), nl,
        NewBoard = Board
    ;
        make_move(Board, BestMove, Side, NewBoard),
        format("Computer played: ~w~n", [BestMove])
    ).
