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
    path_clear_horizontal(Board, FR, FC, TC).  % Nothing blocking the path


% Vertical move
can_slide(Board,FR,FC,TR,FC):-
    FR =\= TR ,   % must move
    get_piece(Board, TR, FC, empty),    % Forces destination to be empty
    \+ (special_cell(TR, FC), \+ get_piece(Board, FR, FC, king)),    
    path_clear_vertical(Board, FC, FR, TR).  % Nothing blocking the path



% path_clear_horizontal(Board, Row, FromCol, ToCol)
% Checks all squares BETWEEN FromCol and ToCol on the same row
% are empty (does not check the destination itself)

path_clear_horizontal(Board,Row,FC,TC):-
    FC < TC,    %moving right
    Mid is FC + 1,
    all_empty_cols(Board,Row,Mid,TC).
    
    
path_clear_horizontal(Board,Row,FC,TC):-
    FC > TC,     %moving left
    Mid is TC + 1,
    all_empty_cols(Board,Row,Mid,FC).


all_empty_cols(_,_,Limit,Limit):- !. %Base case

all_empty_cols(Board,Row,C,Limit):-  % Recursive case
    C < Limit,
    get_piece(Board, Row,C , empty),
    Next is C + 1,
    all_empty_cols(Board,Row,Next,Limit).
    

   


% path_clear_vertical(Board, Col, FromCol, ToCol)
% Checks all squares BETWEEN FromRow and ToRow on the same col
% are empty (does not check the destination itself)


path_clear_vertical(Board,Col,FR,TR):-
    FR < TR ,
    Mid is FR + 1,
    all_empty_rows(Board,Col,Mid,TR).



path_clear_vertical(Board,Col,FR,TR):-
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

    
  


