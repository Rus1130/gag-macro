import pyautogui
import pydirectinput
import tkinter as tk
import time
import json
import keyboard

CONFIG = None

# get the config file
with open("config.json", "r") as f:
    CONFIG = json.loads(f.read().strip())

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

seed_list = [
    "Carrot", "Strawberry", "Blueberry", "Orange Tulip", "Tomato", "Corn", "Daffodil",
    "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut", "Cactus", "Dragonfruit",
    "Mango", "Grape", "Mushroom", "Pepper", "Cacao", "Beanstalk", "Emberlily", "Sugarapple"
]
features_col2 = ["Delta", "Epsilon", "Zeta"]
seed_indexes = None

def launch_window():
    global seed_list, features_col2

    root = tk.Tk()
    root.title("Grow a Garden Macro")
    root.geometry("600x1000")

    def create_group(parent, column, title, features):
        label = tk.Label(parent, text=title, font=("Arial", 12, "bold"))
        label.grid(row=0, column=column, pady=(10, 0))
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

        for i, feature in enumerate(features):
            var = tk.BooleanVar()
            chk = tk.Checkbutton(parent, text=feature, variable=var)
            # set the checkbox to CONFIG.feature, if it exists
            if feature in CONFIG['seeds']:
                var.set(CONFIG['seeds'][feature])
            else:
                var.set(False)

            chk.grid(row=2+i, column=column, sticky="w", padx=30)
            child_vars.append(var)
            child_checks.append(chk)

        return child_vars

    seeds_vars = create_group(root, column=0, title="Seeds", features=seed_list)
    groupB_vars = create_group(root, column=1, title="Group B", features=features_col2)

    def start_macro():
        global loop_counter, seed_indexes
        pyautogui.alert("Macro started! Macro starts 5 seconds after you press OK.")
        time.sleep(5);
        pyautogui.getWindowsWithTitle("Grow a Garden Macro")[0].close()
        pyautogui.getWindowsWithTitle("Roblox")[0].activate()
        selected_seeds = [seed for seed, var in zip(seed_list, seeds_vars) if var.get()]
        seed_indexes = [seed_list.index(seed) for seed in selected_seeds]
        # save the selected seeds to the config file

        CONFIG['seeds'] = {seed: seed in selected_seeds for seed in seed_list}
        with open("config.json", "w") as f:
            f.write(json.dumps(CONFIG, indent=4))

        loop_counter = True
        # return_to_corner()

    start_button = tk.Button(root, text="Start", font=("Arial", 12, "bold"), command=start_macro)
    start_button.grid(row=max(len(seed_list), len(features_col2)) + 2, column=0, columnspan=2, pady=20)

    root.focus_force()
    root.mainloop()

loop_counter = False
last_fired = -1

def return_to_corner():
    pydirectinput.press("w")
    pydirectinput.press("w")
    pydirectinput.press("w")
    pydirectinput.press("w")
    pydirectinput.press("w")
    pydirectinput.press("w")
    pydirectinput.press("w")
    pydirectinput.press("w")
    pydirectinput.press("w")
    pydirectinput.press("w")
    pydirectinput.press("a")
    pydirectinput.press("a")
    pydirectinput.press("a")
    pydirectinput.press("a")
    pydirectinput.press("a")
    pydirectinput.press("a")
    pydirectinput.press("a")
    pydirectinput.press("a")
    pydirectinput.press("a")
    pydirectinput.press("a")

def macro_loop():
    global seed_indexes
    # uncomment vvvv
    # return_to_corner()
    # pydirectinput.press("d", presses=3, interval=0.1)
    # pydirectinput.press("enter")
    time.sleep(1)
    pydirectinput.press("e")
    time.sleep(4)
    pydirectinput.press("s")
    print(seed_indexes)
    # loop through the seed indexes and press them
    i = 0
    while i < len(seed_indexes):
        pydirectinput.press("s", presses=seed_indexes[i], interval=0.1)
        time.sleep(0.5)
        pydirectinput.press("enter", presses=1, interval=0.1)
        time.sleep(0.5)
        pydirectinput.press("s", presses=1, interval=0.1)
        time.sleep(0.5)
        pydirectinput.press("enter", presses=30, interval=0.01)
        time.sleep(0.5)
        pydirectinput.press("w", presses=1, interval=0.1)
        time.sleep(0.5)
        pydirectinput.press("enter", presses=1, interval=0.1)
        time.sleep(0.5)
        pydirectinput.press("\\")
        time.sleep(0.5)
        pydirectinput.press("\\")
        i += 1

    pydirectinput.press("d", presses=5, interval=0.25)
    time.sleep(0.5)
    pydirectinput.press("s", presses=1, interval=0.25)
    time.sleep(0.5)
    pydirectinput.press("d", presses=1)
    time.sleep(0.5)
    pydirectinput.press("enter")
    # continue here
    print("macro loop")

launch_window()

while loop_counter == True:
    current_time = int(time.time())

    if current_time % 10 == 0 and current_time != last_fired:
        macro_loop()
        last_fired = current_time

    if keyboard.is_pressed(CONFIG['kill_key']):
        print(f"{CONFIG['kill_key']} pressed — stopping macro.")
        loop_counter = False
        launch_window()

    time.sleep(0.1)