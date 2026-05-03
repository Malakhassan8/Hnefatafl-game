import tkinter as tk
import subprocess

SIZE = 11
CELL = 45

class TaflGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Hnefatafl Game")

        self.canvas = tk.Canvas(root, width=SIZE*CELL, height=SIZE*CELL)
        self.canvas.pack()

        self.status = tk.Label(root, text="Choose difficulty then play")
        self.status.pack()

        self.diff = tk.StringVar(value="easy")

        tk.OptionMenu(root, self.diff, "easy", "medium", "hard").pack()

        tk.Button(root, text="Start Game", command=self.start_game).pack()

        self.canvas.bind("<Button-1>", self.click)

        self.board = None
        self.selected = None
        self.turn = "attacker"

    # ===================== CONNECT PROLOG =====================
    def run_prolog(self, goal):
        cmd = [
            "swipl",
            "-q",
            "-s", "game.pl",
            "-g", goal,
            "-t", "halt"
        ]
        out = subprocess.run(cmd, capture_output=True, text=True)
        return out.stdout.strip()

    # ===================== START GAME =====================
    def start_game(self):
        out = self.run_prolog("initial_board(B), write(B)")
        self.board = eval(out)
        self.draw()
        self.status.config(text="Game Started - Attackers move first")

    # ===================== DRAW BOARD =====================
    def draw(self):
        self.canvas.delete("all")

        for r in range(SIZE):
            for c in range(SIZE):
                x1, y1 = c*CELL, r*CELL
                x2, y2 = x1+CELL, y1+CELL

                self.canvas.create_rectangle(x1, y1, x2, y2)

                piece = self.board[r][c]

                if piece == "king":
                    color = "gold"
                elif piece == "defender":
                    color = "white"
                elif piece == "attacker":
                    color = "black"
                else:
                    continue

                self.canvas.create_oval(x1+10, y1+10, x2-10, y2-10, fill=color)

    # ===================== CLICK =====================
    def click(self, event):
        r = event.y // CELL
        c = event.x // CELL

        if self.selected is None:
            self.selected = (r, c)
        else:
            fr, fc = self.selected
            tr, tc = r, c
            self.move(fr, fc, tr, tc)
            self.selected = None

    # ===================== MOVE =====================
    def move(self, fr, fc, tr, tc):

        goal = f"gui_move({self.board}, attacker, {fr},{fc},{tr},{tc},B,W)"

        out = self.run_prolog(goal)

        parts = out.split()

        if not parts:
            self.status.config(text="Error from Prolog")
            return

        self.board = eval(parts[0])

        if len(parts) > 1 and parts[1] != "none":
            self.status.config(text=f"Winner: {parts[1]}")
            self.draw()
            return

        self.switch_turn()
        self.draw()

    # ===================== TURN =====================
    def switch_turn(self):
        self.turn = "defender" if self.turn == "attacker" else "attacker"
        self.status.config(text=f"Turn: {self.turn}")


root = tk.Tk()
TaflGUI(root)
root.mainloop()
