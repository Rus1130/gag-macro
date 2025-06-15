# How to use
1. Make sure that your camera is positioned like so:
![alignment image](alignment.png "Alignment")
Try to have the camera as level as possible.
2. Make sure that the ui navigation toggle is set to "On".
![UI navigation](uinav.png "UI Navigation")
3. Make sure that this is selected by the UI navigation toggle: (use WASD/arroy keys to move to there)
![start](start.png "start")
4. Make sure that the game is in fullscreen mode.
5. Make sure that the Recall Wrench is in your **2nd** slot and is not equipped when the macro starts.
![Wrench](wrench.png "Wrench")
6. Start the macro by clicking the "Start" button in the UI.
**Make sure that there are no selected seeds or gears in the shop!**
Bad:
![bad selection](bad_selection.png "Bad selection")
Good:
![good selection](good_selection.png "Good selection")
Also: make sure that your last prior selected seed was carrot, before starting the macro
# config
The config file is located at `config.json`. It contains the following:
* `buy_counts`: A dictionary of seeds and their respective counts to buy.
* `buy_seeds`: A dictionary of seeds and whether to buy them or not.
* `kill_key`: The key to press to stop the macro. Default is `F6`. It is not that reliable, so if it does not work, move the cursor to any corner of the screen and the program will terminate.