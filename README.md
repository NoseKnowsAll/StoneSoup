# StoneSoup
Julia REPL version of "Stone Soup" board game by Avenue B Games.

To play, simply type `include("game.jl")` in the Julia REPL, and run `play_game(num_players)`. Game allows for 2-4 players.

In "Stone Soup," the players attempt to complete recipes by placing ingredients in several communal pots. Each player is trying to complete their own secret recipes though, so watch out for your opponents trying to steal your progress and make their own recipe instead! Each completed recipe has a specified point value, and the first player to reach 10 points wins.

If placing an ingredient in a pot completes a recipe, any player may choose to claim the recipe and clear the pot. When this happens, all players with this recipe get the points and get a new secret recipe. Note that you cannot claim two recipes with one pot.

When an ingredient is placed in a pot, any other player may call a bluff. If the player who placed the ingredient has a viable recipe for the pot, then they get the points for having completing their recipe. If they do not have a viable recipe for the pot, then the player who called the bluff steals a random recipe from this player. In either case, the pot is cleared.

While it should be possible to play this game purely in text mode, I have found that it works best to have the image of all the Stone Soup recipes open separately as a reference for all players. If you are playing this game online with friends (via some voice chat and screen share service such as Discord), then I recommend each player open up the recipes image as well as follow along the game. This is especially useful when deciding which pot to place your ingredients in and whether or not you think a player is bluffing or not.

The rest of the game should be self-explanatory by following the prompts in the REPL. If there is any confusion, or if you find an error, please let me know!
