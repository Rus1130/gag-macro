import pyautogui
import tkinter as tk
import time

root = tk.Tk()
root.title("Grow a Garden Macro")
root.geometry("600x1000")

# Helper function to build a checkbox group
def create_group(parent, column, title, features):
    # Group label
    label = tk.Label(parent, text=title, font=("Arial", 12, "bold"))
    label.grid(row=0, column=column, pady=(10, 0))

    # Master checkbox
    master_var = tk.BooleanVar()
    child_vars = []
    child_checks = []

    def toggle_all():
        state = master_var.get()
        for var, chk in zip(child_vars, child_checks):
            var.set(state)
            chk.config(state="disabled" if state else "normal")

    master_checkbox = tk.Checkbutton(parent, text="Select All", variable=master_var, command=toggle_all)
    master_checkbox.grid(row=1, column=column, sticky="w", padx=10, pady=5)

    # Child checkboxes
    for i, feature in enumerate(features):
        var = tk.BooleanVar()
        chk = tk.Checkbutton(parent, text=feature, variable=var)
        chk.grid(row=2+i, column=column, sticky="w", padx=30)
        child_vars.append(var)
        child_checks.append(chk)

    return child_vars

# Example features per group
seed_list = [
    "Carrot", "Strawberry", "Blueberry", "Orange Tulip", "Tomato", "Corn", "Daffodil",
    "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut", "Cactus", "Dragonfruit",
    "Mango", "Grape", "Mushroom", "Pepper", "Cacao", "Beanstalk", "Emberlily", "Sugarapple"
]
features_col2 = ["Delta", "Epsilon", "Zeta"]

# Create both groups
seed_checks = create_group(root, column=0, title="Seeds", features=seed_list)
create_group(root, column=1, title="Group B", features=features_col2)

loop_counter = False
last_fired = -1

# Add the Start button at the bottom
def start_macro():
    global loop_counter
    pyautogui.getWindowsWithTitle("Grow a Garden Macro")[0].minimize()
    selected_seeds = [seed for seed, var in zip(seed_list, seed_checks) if var.get()]
    seed_indexes = [seed_list.index(seed) for seed in selected_seeds]
    print("Selected Seeds:", seed_indexes)
    loop_counter = True

def macro_loop():
    print("macro loop")

start_button = tk.Button(root, text="Start", font=("Arial", 12, "bold"), command=start_macro)
start_button.grid(row=max(len(seed_list), len(features_col2)) + 2, column=0, columnspan=2, pady=20)

root.mainloop()

while loop_counter == True:
    current_time = int(time.time())
    print(current_time)
    # if current_time % 15 == 0 and current_time != last_fired:
    #     macro_loop()
    #     last_fired = current_time
    # time.sleep(0.1)
