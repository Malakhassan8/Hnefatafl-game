% Difficulty levels -> search depth
difficulty_depth(easy,   1).
difficulty_depth(medium, 3).
difficulty_depth(hard,   5).

% ---------------------------------------------------------------------
% HEURISTIC / UTILITY

% Count how many pieces a specific side has on the board.
count_pieces(Board, Side, Count) :-
    findall(1, (
        between(0, 10, R),  % scan all board positions
        between(0, 10, C),
        get_piece(Board, R, C, Piece), % retrieve each piece
        piece_belongs_to(Piece, Side) % check if it belongs to the side
    ), Ones),
    length(Ones, Count).


% Calculate the distance from the king’s position to all corners, then take the smallest one.
manhattan_to_nearest_corner(KR, KC, Dist) :-
    findall(D, (
        corner(CR, CC),
        D is abs(KR - CR) + abs(KC - CC)
    ), Ds),
    min_list(Ds, Dist).


% How many moves the king has in the board
king_legal_moves_count(Board, Count) :-
    find_king(Board, KR, KC), % get king position
    findall(1, (
        between(0, 10, TR),
        between(0, 10, TC),
        can_slide(Board, KR, KC, TR, TC) % check if king can move to each poistion in the board stline(no diagonals), availabe or not
    ), Ones),
    length(Ones, Count).


% Number of attackers directly next to the king(up, down, left, right)
attackers_adjacent_to_king(Board, Count) :-
    find_king(Board, KR, KC),
    findall(1, (
        member((DR, DC), [(-1,0),(1,0),(0,-1),(0,1)]), % define 4 directions and check them
        NR is KR + DR, % get neighbors positions
        NC is KC + DC,           
        NR >= 0, NR =< 10, % ensure position is inside the board
        NC >= 0, NC =< 10,
        get_piece(Board, NR, NC, attacker) % if it's attacker
    ), Ones),
    length(Ones, Count).


% ---------------------------------------------------------------------
% Components (all from the DEFENDER's perspective, then flipped for attacker):
evaluate(Board, Side, Score) :-
    % game ending conditions
    ( king_escaped(Board)  -> RawScore =  100000 % defender wins
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
        DistScore is -CornerDist * 8,   % defender wants small distance

        % 3. King moves
        king_legal_moves_count(Board, KingMoves),
        MobilityScore is KingMoves * 4, % more legal moves → good for defender

        % 4. Threat level
        attackers_adjacent_to_king(Board, Threats),
        ThreatScore is -Threats * 15,

        RawScore is PieceDiff + DistScore + MobilityScore + ThreatScore
    ),
    /* Flip sign if we are evaluating from the attacker's perspective*/
    ( Side = attacker -> Score is -RawScore ; Score = RawScore ).


% ---------------------------------------------------------------------
% ALPHA-BETA PRUNING

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
    valid_moves(Board, Side, Moves), % get all valid moves from current player
    Moves \= [],
    opposite_side(Side, OppSide), 
    NewDepth is Depth - 1,
    ab_loop(Board, Moves, NewDepth, Alpha, Beta, Side, OppSide,
            none, Alpha, BestMove, BestScore).

% No moves available (won't normally reach here if game_over is correct)
alpha_beta(Board, _Depth, _Alpha, _Beta, Side, none, Score) :-
    evaluate(Board, Side, Score).


% ---------------------------------------------------------------------
% defines whose turn comes next & switch turns
opposite_side(attacker, defender).
opposite_side(defender, attacker).


% ---------------------------------------------------------------------
% Iterates over the move list, updating alpha and pruning when possible.
 
% Base case: no moves left
ab_loop(_Board, [], _Depth, _Alpha, _Beta, _Side, _OppSide,
        BestMove, BestScore, BestMove, BestScore). % return the best move found so far

% Recursive case
ab_loop(Board, [Move|Rest], Depth, Alpha, Beta, Side, OppSide,
        CurBestMove, CurBestScore, BestMove, BestScore) :-

    % show the move on the board
    make_move(Board, Move, Side, NewBoard), 

    % Evaluate other player move 
    alpha_beta(NewBoard, Depth, -Beta, -Alpha, OppSide, _, OppScore),
    Score is -OppScore, % flip the sign and maximize to convert it into one perspective (maximizing)

    % Update best move and alpha
    ( Score > CurBestScore ->
        NewBestMove  = Move,
        NewBestScore = Score
    ;
        NewBestMove  = CurBestMove,
        NewBestScore = CurBestScore
    ),

    NewAlpha is max(Alpha, NewBestScore),

    % Beta = opponent’s best option
    % best score the current player so good that the opponent will avoid this branch completely
    ( NewAlpha >= Beta ->
        BestMove  = NewBestMove,
        BestScore = NewBestScore         
    ;
    	% if no pruning then continue checking remaining moves
        ab_loop(Board, Rest, Depth, NewAlpha, Beta, Side, OppSide,
                NewBestMove, NewBestScore, BestMove, BestScore)
    ).


% ---------------------------------------------------------------------
% PUBLIC INTERFACE
best_move(Board, Side, Difficulty, BestMove) :-
    difficulty_depth(Difficulty, Depth),
    alpha_beta(Board, Depth, -1000000, 1000000, Side, BestMove, _Score).


  
