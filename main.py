import pyautogui
import pydirectinput
import tkinter as tk
import time
import json
import keyboard

CONFIG = None
pyautogui.MINIMUM_DURATION = 0.01

# get the config file
with open("config.jsonc", "r") as f:
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
    "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut", "Cactus", "Dragon Fruit",
    "Mango", "Grape", "Mushroom", "Pepper", "Cacao", "Beanstalk", "Ember Lily", "Sugar Apple"
]
gear_list = [ 
    "Watering Can", "Trowel", "Recall Wrench", "Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler", "Lightning Rod", "Master Sprinkler", "Cleaning Spray", "Favorite Tool", "Harvest Tool", "Friendship Pot"
]

seed_indexes = None
gear_indexes = None

def launch_window():
    global seed_list, gear_list

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

            if feature in CONFIG['gears']:
                var.set(CONFIG['gears'][feature])

            chk.grid(row=2+i, column=column, sticky="w", padx=30)
            child_vars.append(var)
            child_checks.append(chk)

        return child_vars

    seeds_vars = create_group(root, column=0, title="Seeds", features=seed_list)
    gear_vars = create_group(root, column=1, title="Gears", features=gear_list)

    def start_macro():
        global loop_counter, seed_indexes, gear_indexes
        pyautogui.alert("Macro started! Macro starts 5 seconds after you press OK.")
        time.sleep(5);
        pyautogui.getWindowsWithTitle("Grow a Garden Macro")[0].close()
        pyautogui.getWindowsWithTitle("Roblox")[0].activate()

        selected_seeds = [seed for seed, var in zip(seed_list, seeds_vars) if var.get()]
        selected_gears = [gear for gear, var in zip(gear_list, gear_vars) if var.get()]
        seed_indexes = [seed_list.index(seed) for seed in selected_seeds]
        gear_indexes = [gear_list.index(gear) for gear in selected_gears]
        # save the selected seeds to the config file

        CONFIG['seeds'] = {seed: seed in selected_seeds for seed in seed_list}
        CONFIG['gears'] = {gear: gear in selected_gears for gear in gear_list}

        with open("config.jsonc", "w") as f:
            f.write(json.dumps(CONFIG, indent=4))


        loop_counter = True

    start_button = tk.Button(root, text="Start", font=("Arial", 12, "bold"), command=start_macro)
    start_button.grid(row=max(len(seed_list), len(gear_list)) + 2, column=0, columnspan=2, pady=20)

    root.focus_force()
    root.mainloop()

loop_counter = False
last_fired = -1

def macro_loop():
    global seed_indexes, gear_indexes, gear_list, seed_list
    # seed macro =====================================================================================
    pydirectinput.press("d", presses=3, interval=0.1)
    pydirectinput.press("enter")
    time.sleep(1)
    pydirectinput.press("e")
    time.sleep(5)
    pydirectinput.press("down")

    # loop through the seed indexes and press them
    seed_i = 0
    while seed_i < len(seed_indexes):
        pydirectinput.press("s", presses=seed_indexes[seed_i], interval=0.1)
        time.sleep(0.5)
        pydirectinput.press("enter", presses=1, interval=0.05)
        time.sleep(0.5)
        pydirectinput.press("s", presses=1, interval=0.05)
        time.sleep(0.5)
        buyCount = CONFIG['buy_counts'].get(seed_list[seed_indexes[seed_i]], 1)  # Default to 1 if not specified
        pydirectinput.press("enter", presses=buyCount, interval=0.05)
        time.sleep(0.5)
        pydirectinput.press("w", presses=1, interval=0.05)
        time.sleep(0.5)
        pydirectinput.press("enter", presses=1, interval=0.05)
        time.sleep(0.5)
        pydirectinput.press("w", presses=seed_indexes[seed_i], interval=0.1)
        seed_i += 1

    pydirectinput.press("w")
    time.sleep(0.5)
    pydirectinput.press("enter")
    time.sleep(1)
    pydirectinput.press("w")
    time.sleep(0.5)
    pydirectinput.press("a")
    time.sleep(0.5)
    pydirectinput.press("enter")
    time.sleep(0.5)
    pydirectinput.press("a", presses=4, interval=0.1)
    time.sleep(0.5)


    # gear macro =====================================================================================
    # pydirectinput.press("2")
    # time.sleep(0.2)
    # pydirectinput.click()
    # time.sleep(0.5)
    # pydirectinput.press("e")
    # screen_width, screen_height = pyautogui.size()
    # center_x = screen_width // 2
    # center_y = screen_height // 2

    # pyautogui.moveTo(center_x, center_y, duration=0.1)

    # time.sleep(2)

    # weight = 0.1
    # shift_x = int(center_x + (screen_width - center_x) * weight)
    # shift_y = center_y  # keep same y

    # smooth_move_to(shift_x, shift_y, steps=10, duration=0.02)
    # time.sleep(0.5)
    # smooth_move_to(shift_x, shift_y-25, steps=10, duration=0.02)
    # pydirectinput.click()
    # time.sleep(2)
    # pydirectinput.press("\\")
    # time.sleep(4)
    # pydirectinput.press("d", presses=3, interval=0.1)
    # time.sleep(0.5)
    # pydirectinput.press("s")
    # # now move the mouse halfway between where it is and the right edge of the screen
    # gear_i = 0
    # while gear_i < len(gear_indexes):
    #     pydirectinput.press("s", presses=gear_indexes[gear_i], interval=0.1)
    #     time.sleep(0.5)
    #     pydirectinput.press("enter", presses=1, interval=0.05)
    #     time.sleep(0.5)
    #     pydirectinput.press("s", presses=1, interval=0.05)
    #     time.sleep(0.5)
    #     buyCount = CONFIG['buy_counts'].get(gear_list[gear_indexes[gear_i]], 1)  # Default to 1 if not specified
    #     pydirectinput.press("enter", presses=buyCount, interval=0.05)
    #     time.sleep(0.5)
    #     pydirectinput.press("w", presses=1, interval=0.05)
    #     time.sleep(0.5)
    #     pydirectinput.press("enter", presses=1, interval=0.05)
    #     time.sleep(0.5)
    #     pydirectinput.press("w", presses=gear_indexes[gear_i], interval=0.1)
    #     gear_i += 1

    # pydirectinput.press("w")
    # time.sleep(0.5)
    # pydirectinput.press("enter")
    # time.sleep(1)
    # pydirectinput.press("w")
    # time.sleep(0.5)
    # pydirectinput.press("a")
    # time.sleep(0.5)
    # pydirectinput.press("enter")
    # time.sleep(0.5)
    # pydirectinput.press("a", presses=4, interval=0.1)
    # time.sleep(0.5)



    # continue here
    print("macro loop")

launch_window()

def smooth_move_to(x, y, steps=50, duration=0.2):
    start_x, start_y = pydirectinput.position()
    delta_x = (x - start_x) / steps
    delta_y = (y - start_y) / steps
    delay = duration / steps

    for i in range(steps):
        new_x = int(start_x + delta_x * i)
        new_y = int(start_y + delta_y * i)
        pydirectinput.moveTo(new_x, new_y)
        time.sleep(delay)

while loop_counter == True:
    current_time = int(time.time())

    if keyboard.is_pressed(CONFIG['kill_key']):
        print(f"{CONFIG['kill_key']} pressed — stopping macro.")
        loop_counter = False
        launch_window()
        break

    if current_time % CONFIG['shop_timer'] == 0 and current_time != last_fired:
        macro_loop()
        last_fired = current_time

    if keyboard.is_pressed(CONFIG['kill_key']):
        print(f"{CONFIG['kill_key']} pressed — stopping macro.")
        loop_counter = False
        launch_window()
        break;

    time.sleep(0.1)