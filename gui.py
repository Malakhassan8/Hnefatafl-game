import tkinter as tk
from tkinter import messagebox, ttk
import subprocess

# ─────────────────────────────────────────────
# PROLOG BRIDGE
# ─────────────────────────────────────────────
def query_prolog(query):
    cmd = [
        r"C:\Program Files\swipl\bin\swipl.exe",
        "-q",
        "-s", r"C:\Users\lenovo\Downloads\Hnefatafl-game-main\Hnefatafl-game-main\whole_code _so_far.pl",
        "-g", query
        "-t", "halt"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.strip()

# ─────────────────────────────────────────────
# BOARD CONVERSION
# ─────────────────────────────────────────────
def py_to_prolog(board):
    mapping = {0:"empty", 1:"attacker", 2:"defender", 3:"king"}
    return "[" + ",".join(mapping[x] for x in board) + "]"

def prolog_to_py(board_str):
    mapping = {"empty":0, "attacker":1, "defender":2, "king":3}
    items = board_str.strip("[]").split(",")
    return [mapping[i.strip()] for i in items if i.strip()]

def parse_move(move_str):
    nums = move_str.strip()[5:-1].split(",")
    return tuple(map(int, nums))

# ─────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────
EMPTY, ATTACKER, DEFENDER, KING = 0,1,2,3

CELL = 56
PAD  = 30

BG          = "#1a1208"
BOARD_LIGHT = "#c8a96e"
BOARD_ALT   = "#b8955a"
HIGHLIGHT   = "#f0e040"
MOVE_CLR    = "#4a9e4a"

# ─────────────────────────────────────────────
# GUI APP
# ─────────────────────────────────────────────
class App(tk.Tk):

    def __init__(self):
        super().__init__()
        self.title("Hnefatafl — Prolog Engine")
        self.configure(bg=BG)

        self.player_side = None
        self.difficulty = None

        self._build_start_menu()

    # ─────────────────────────────────────────
    # START MENU
    # ─────────────────────────────────────────
    def _build_start_menu(self):
        self.menu = tk.Frame(self, bg=BG)
        self.menu.pack(padx=40, pady=40)

        tk.Label(self.menu, text="HNEFATAFL",
                 font=("Arial", 22, "bold"),
                 fg="white", bg=BG).pack(pady=10)

        tk.Label(self.menu, text="Choose Side", bg=BG, fg="white").pack()

        self.side_var = tk.StringVar(value="defender")
        ttk.Combobox(self.menu, textvariable=self.side_var,
                     values=["attacker", "defender"],
                     state="readonly").pack(pady=5)

        tk.Label(self.menu, text="Choose Difficulty", bg=BG, fg="white").pack()

        self.diff_var = tk.StringVar(value="medium")
        ttk.Combobox(self.menu, textvariable=self.diff_var,
                     values=["easy", "medium", "hard"],
                     state="readonly").pack(pady=5)

        tk.Button(self.menu, text="Start Game",
                  command=self._start_game,
                  bg="green", fg="white").pack(pady=20)

    # ─────────────────────────────────────────
    # GAME START
    # ─────────────────────────────────────────
    def _start_game(self):
        self.menu.destroy()

        self.player_side = self.side_var.get()
        self.difficulty = self.diff_var.get()

        size = CELL*11 + PAD*2
        self.canvas = tk.Canvas(self, width=size, height=size, bg=BG)
        self.canvas.pack()
        self.canvas.bind("<Button-1>", self.click)

        res = query_prolog("setup_board(B), write(B)")
        self.board = prolog_to_py(res)

        self.selected = None
        self.valid_moves = []

        self.draw()

    # ─────────────────────────────────────────
    # DRAW BOARD
    # ─────────────────────────────────────────
    def draw(self):
        self.canvas.delete("all")

        for r in range(11):
            for c in range(11):
                x1 = PAD + c*CELL
                y1 = PAD + r*CELL
                x2 = x1 + CELL
                y2 = y1 + CELL

                color = BOARD_LIGHT if (r+c)%2==0 else BOARD_ALT

                if self.selected == (r,c):
                    color = HIGHLIGHT
                elif (r,c) in self.valid_moves:
                    color = MOVE_CLR

                self.canvas.create_rectangle(x1,y1,x2,y2, fill=color)

                piece = self.board[r*11+c]
                if piece != EMPTY:
                    self.canvas.create_text(
                        x1+CELL//2, y1+CELL//2,
                        text=["","A","D","K"][piece],
                        font=("Arial",16,"bold")
                    )

    # ─────────────────────────────────────────
    # CLICK HANDLER
    # ─────────────────────────────────────────
    def click(self, event):
        c = (event.x - PAD)//CELL
        r = (event.y - PAD)//CELL
        if not (0<=r<=10 and 0<=c<=10):
            return

        if self.selected is None:
            piece = self.board[r*11+c]
            if (self.player_side == "attacker" and piece==1) or \
               (self.player_side == "defender" and piece in [2,3]):

                self.selected = (r,c)
                self.get_valid_moves(r,c)
                self.draw()
        else:
            if (r,c) in self.valid_moves:
                self.make_move(*self.selected, r, c)
                self.selected = None
                self.valid_moves = []
                self.draw()
                self.after(200, self.ai_turn)
            else:
                self.selected = None
                self.valid_moves = []
                self.draw()

    # ─────────────────────────────────────────
    # VALID MOVES
    # ─────────────────────────────────────────
    def get_valid_moves(self, r, c):
        board_str = py_to_prolog(self.board)
        query = f"valid_moves({board_str}, {self.player_side}, M), write(M)"
        res = query_prolog(query)

        self.valid_moves = []
        moves = res.strip("[]").split("),")

        for m in moves:
            if "move" in m:
                m = m.replace("move(","").replace(")","")
                fr,fc,tr,tc = map(int,m.split(","))
                if fr==r and fc==c:
                    self.valid_moves.append((tr,tc))

    # ─────────────────────────────────────────
    # MAKE MOVE
    # ─────────────────────────────────────────
    def make_move(self, fr, fc, tr, tc):
        board_str = py_to_prolog(self.board)
        query = f"make_move({board_str}, move({fr},{fc},{tr},{tc}), {self.player_side}, NB), write(NB)"
        res = query_prolog(query)
        self.board = prolog_to_py(res)

    # ─────────────────────────────────────────
    # AI TURN
    # ─────────────────────────────────────────
    def ai_turn(self):
        board_str = py_to_prolog(self.board)

        query = f"best_move({board_str}, attacker, {self.difficulty}, M), write(M)"
        move_str = query_prolog(query)

        if "move" not in move_str:
            return

        fr,fc,tr,tc = parse_move(move_str)

        query = f"make_move({board_str}, move({fr},{fc},{tr},{tc}), attacker, NB), write(NB)"
        res = query_prolog(query)

        self.board = prolog_to_py(res)
        self.draw()

        winner = query_prolog(f"(game_over({py_to_prolog(self.board)}, W) -> write(W); write(none))")
        if winner != "none":
            messagebox.showinfo("Game Over", f"{winner} wins!")

# ─────────────────────────────────────────────
# RUN
# ─────────────────────────────────────────────
if __name__ == "__main__":
    app = App()
    app.mainloop()
