%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     STUDENT 5 — GAME CONTROLLER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------------------- Play/0 ---------------------------------
play :-
    write('Choose difficulty (easy/medium/hard): '), nl,
    read(Diff),
    difficulty_depth(Diff, Depth),
    initial_board(Board),
    print_board(Board),
    game_loop(Board, attacker, Depth).

% ----------------------------- Difficulty -----------------------------
difficulty_depth(easy, 1).
difficulty_depth(medium, 3).
difficulty_depth(hard, 5).

% ------------------------- Turn Switching ----------------------------
switch_turn(attacker, defender).
switch_turn(defender, attacker).

% -------------------------- User Input -------------------------------
read_user_move(Move) :-
    write('Enter your move as move(FR,FC,TR,TC).'), nl,
    read(Move).

% --------------------------- Take Turn -------------------------------
take_turn(Board, attacker, Depth, NewBoard) :-
    write('[Computer - Attackers] is thinking...'), nl,
    alpha_beta(Board, Depth, -10000, 10000, attacker, BestMove, _Score),
    write('Computer plays: '), write(BestMove), nl,
    apply_move(Board, BestMove, TempBoard),
    apply_captures(TempBoard, BestMove, attacker, NewBoard).

take_turn(Board, defender, _Depth, NewBoard) :-
    write('[Your Turn - Defenders]'), nl,
    repeat,
        read_user_move(Move),
        ( valid_moves(Board, defender, Moves),
          member(Move, Moves) ->
                apply_move(Board, Move, TempBoard),
                apply_captures(TempBoard, Move, defender, NewBoard),
                !
        ;
            write('Invalid move. Try again.'), nl, fail
        ).

% ------------------------- Game Loop --------------------------------
game_loop(Board, Side, Depth) :-

    % End-of-game check
    ( game_over(Board, Winner) ->
        nl, write('=== GAME OVER ==='), nl,
        write('Winner: '), write(Winner), nl
    ;
        take_turn(Board, Side, Depth, NewBoard),
        print_board(NewBoard),
        switch_turn(Side, NextSide),
        game_loop(NewBoard, NextSide, Depth)
    ).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI INTERFACE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

initial_board(B) :-
    setup_board(B).

gui_move(Board, Side, FR,FC,TR,TC, NewBoard, Winner) :-
    make_move(Board, move(FR,FC,TR,TC), Side, B1),
    ( game_over(B1, W) ->
        Winner = W,
        NewBoard = B1
    ;
        Winner = none,
        NewBoard = B1
    ).
