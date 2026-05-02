% ---------------------------------------------------------------------
% Difficulty levels -> search depth
% ---------------------------------------------------------------------
difficulty_depth(easy,   1).
difficulty_depth(medium, 3).
difficulty_depth(hard,   5).


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
% Positive score = good for Side.
% --------------------------------------------------------------------
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


  
