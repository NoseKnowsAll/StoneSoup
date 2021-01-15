" Score needed to win the game "
win_score = 10
" Ingredient for use in constructing Recipes "
@enum Ingredient begin
    Onion = 1
    Oil = 2
    Tomato = 3
    Seasoning = 4
    Beef = 5
    Carrot = 6
    Bean = 7
    Chicken = 8
end
" Number of each ingredient found in ingredient deck "
n_ingredients_in_deck = [15, 13, 12, 10, 8, 8, 6, 5]
" Number of stones in river (center cards that anyone can draw from) "
n_river_stones = 3
" Number of stones each player starts the game with "
n_player_stones = 2
" Number of actions per turn "
n_actions = 2
" Number of lines in console - used for clearing console naively "
console_size = 50
" Number of recipes that each player starts with "
min_recipes = 2
