using Random
include("parameters.jl")

"""
    function draw!(from_deck, to_deck, n_cards=1)
Draw a specified number of cards from top of a given deck to top a given deck
"""
function draw!(from_deck, to_deck, n_cards=1)
    for i = 1:n_cards
        if !isempty(from_deck)
            card = pop!(from_deck)
        else
            error("Insufficient cards in deck to draw $n_cards")
        end
        push!(to_deck, card)
    end
end
"""
    function input_line(prompt="", io_I::IO=stdin, io_O::IO=stdout)
Print prompt to output buffer (default: `stdout`) and input one line from
input buffer (default: `stdin`), returning line as a `String`.
"""
function input_line(prompt="", io_I::IO=stdin, io_O::IO=stdout)
    println(io_O, prompt)
    readline(io_I)
end
"""
    function input_index(prompt, max_index, min_index=1)
Print prompt "Choose the index of the `prompt` (or [c]ancel):" and keep
attempting to get an integer index from user until it falls within inclusive
range min_index <= user input <= max_index
"""
function input_index(prompt, max_index, min_index=1)
    valid = false
    index = -1
    while !valid
        string = input_line("Choose the index of the $prompt (or [c]ancel):")
        try
            index = parse(Int,string)
            if min_index <= index <= max_index
                valid = true
            else
                println("Invalid index!")
            end
        catch
            if string ∈ ["cancel", "Cancel", "c", "C"]
                return false
            else
                println("Invalid index!")
            end
        end
    end
    return index
end
"""
    function multiline_print(array, name=nothing)
Fancy printing of arrays on multiple lines - one element per line.
Optionally print name above the array
"""
function multiline_print(array, name=nothing)
    if !isnothing(name)
        println("$name:")
    end
    for element in array
        println(element)
    end
end

" `Recipe` is made up of a list of `Ingredient`s and point value earned for making it "
struct Recipe
    name::String
    ingredients::Array{Ingredient,1}
    pts::Int
end
" Fancy printing of `Recipe` "
function Base.show(io::IO, recipe::Recipe)
    print(io, recipe.name, ": ")
    print(io, recipe.ingredients)
    print(io, ", worth $(recipe.pts) pts")
end
" Player has a name, ingredients/stones list, and active recipes "
mutable struct Player
    name::String
    ingredients::Array{Ingredient,1}
    recipes::Array{Recipe,1}
    pts::Int
    Player(name) = new(name, Ingredient[], Recipe[], 0)
end
" Fancy printing of `Player` - don't reveal private recipes "
function Base.show(io::IO, player::Player)
    print(io, "$(player.name): $(player.ingredients), has $(player.pts) pts")
end

" Return a list of `Recipe`s and create the initialized recipe deck "
function init_recipes()
    barbecue = Recipe("Barbecue", [Bean, Beef, Oil, Onion], 6)
    beef_stew = Recipe("Beef Stew", [Beef, Carrot, Tomato, Seasoning], 5)
    beef_medley = Recipe("Beef Medley", [Beef, Oil, Tomato], 3)
    chicken_soup = Recipe("Chicken Soup", [Carrot, Chicken, Onion, Seasoning], 6)
    fried_chicken = Recipe("Fried Chicken", [Chicken, Oil, Seasoning], 3)
    fried_veggies = Recipe("Fried Veggies", [Tomato, Oil, Onion], 3)
    onion_rings = Recipe("Onion Rings", [Oil, Onion], 1)
    onion_soup = Recipe("Onion Soup", [Oil, Onion, Seasoning], 3)
    veggie_delight = Recipe("Veggie Delight", [Bean, Carrot, Onion, Tomato], 5)
    carrot_soup = Recipe("Carrot Soup", [Carrot, Onion, Seasoning, Tomato], 6)
    chili = Recipe("Chili", [Bean, Onion, Tomato], 3)
    stir_fry = Recipe("Stir Fry", [Beef, Onion], 1)
    recipes = [barbecue, beef_stew, beef_medley, chicken_soup, fried_chicken,
        fried_veggies, onion_rings, onion_soup, veggie_delight, carrot_soup,
        chili, stir_fry]
    recipe_deck = shuffle!([barbecue, beef_stew, beef_stew, beef_medley,
        beef_medley, chicken_soup, fried_chicken, fried_chicken, fried_veggies,
        fried_veggies, onion_rings, onion_rings, onion_soup, onion_soup,
        veggie_delight, veggie_delight, carrot_soup, chili, stir_fry])
    return recipes, recipe_deck
end
" Return the initialized ingredient deck "
function init_ingredients()
    ingredient_deck = Ingredient[]
    for ingredient in instances(Ingredient)
        append!(ingredient_deck, fill(ingredient, n_ingredients_in_deck[Int(ingredient)]))
    end
    return shuffle!(ingredient_deck)
end
" Initialize the pots "
function init_pots(num_players)
    pots = Array{Array{Ingredient,1},1}(undef, num_players)
    for i = 1:num_players
        pots[i] = Ingredient[]
    end
    return pots
end
" Initialize the river (center cards that anyone can draw from) "
function init_river!(ingredient_deck)
    river = Ingredient[]
    draw!(ingredient_deck, river, n_river_stones)
    return river
end
" Initialize the player decks "
function init_players!(num_players, ingredient_deck, recipe_deck)
    " Choose 2 out of 3 recipes from the deck according to user input "
    function choose_recipes!(name, eventual_recipes, recipe_deck)
        draw!(recipe_deck, eventual_recipes, 3)
        hide_info(name, (eventual_recipes,"You randomly drew these recipes"), false)
        index = input_index("recipe you wish to return to the deck",length(eventual_recipes))
        while index == false
            index = input_index("recipe you wish to return to the deck",length(eventual_recipes))
        end
        to_reshuffle = eventual_recipes[index]
        deleteat!(eventual_recipes, index)
        hide_info(name, (eventual_recipes,"You will play the game with these recipes"), true)
        # Add the rejected recipe back to global recipe deck and reshuffle
        push!(recipe_deck, to_reshuffle)
        shuffle!(recipe_deck)
    end
    players = Array{Player,1}(undef, num_players)
    println("The player who ate last goes first.")
    for i = 1:num_players
        # Get names
        name = input_line("Player $i name:")
        players[i] = Player(name)
        # Initialize ingredients
        draw!(ingredient_deck, players[i].ingredients, n_player_stones)
        # Initialize recipes
        choose_recipes!(players[i].name, players[i].recipes, recipe_deck)
    end
    return players
end
" Initialize the game states "
function init_game(num_players)
    println("Welcome to STONE SOUP, a game by Avenue B Games\n")
    recipes, recipe_deck = init_recipes()
    ingredient_deck = init_ingredients()
    discard_pile = Ingredient[]
    draw!(ingredient_deck, discard_pile) # Seed the discard pile
    pots = init_pots(num_players)
    river = init_river!(ingredient_deck)
    players = init_players!(num_players, ingredient_deck, recipe_deck)
    curr_player = 1
    return (recipes=recipes, recipe_deck=recipe_deck, ingredient_deck=ingredient_deck, discard_pile=discard_pile, pots=pots, river=river, players=players, curr_player=curr_player)
end

" Print the current game state to console "
function print_game_state(discard_pile, river, pots, players, curr_player)
    if !isempty(discard_pile)
        println("Last discarded ingredient: $(discard_pile[end])")
    end
    println("River: $river")
    multiline_print(pots,"Pots")
    multiline_print(players, "Players")
    println("Current player: $(players[curr_player].name)")
    println()
end
" Print given info, but only allow for `name` to view it "
function hide_info(name, info::String, hide=true)
    println("ONLY $(uppercase(name)) MAY VIEW THIS INFO. Press enter to view")
    readline()
    println(info)
    if hide
        println("Press enter to hide this information")
        readline()
        [println() for i = 1:console_size]
    end
end
function hide_info(name, info::Tuple, hide=true)
    println("ONLY $(uppercase(name)) MAY VIEW THIS INFO. Press enter to view")
    readline()
    multiline_print(first(info), last(info))
    if hide
        println("Press enter to hide this information")
        readline()
        [println() for i = 1:console_size]
    end
end
" Draw an ingredient from either the discard pile, river, or ingredient_deck "
function draw_stone!(ingredient_deck, discard_pile, river, player)
    valid = false
    if !isempty(discard_pile)
        println("Last discarded ingredient: $(discard_pile[end])")
    end
    println("River: $river\n")
    to_draw = nothing
    while !valid
        result = input_line("First draw an ingredient from either the [d]iscard pile, [r]iver, or [i]ngredient deck (or [c]ancel):")
        if result ∈ ["discard", "discard pile", "d", "D"]
            if isempty(discard_pile)
                println("Discard pile is currently empty!")
                continue
            end
            valid = true
            to_draw = pop!(discard_pile)
        elseif result ∈ ["river", "r"]
            index = input_index("ingredient in river you wish to draw",length(river))
            if index == false
                continue
            end
            valid = true
            to_draw = deepcopy(river[index])
            to_river = pop!(ingredient_deck)
            river[index] = to_river
        elseif result ∈ ["ingredient", "ingredient deck", "i", "I"]
            valid = true
            to_draw = pop!(ingredient_deck)
        elseif result ∈ ["cancel", "Cancel", "c", "C"]
            return false
        else
            println("Invalid action - please try again")
        end
    end
    push!(player.ingredients, to_draw)
    println("You drew: $to_draw\n")
    return true
end
" Discard a specific ingredient stone from player's hand of their choice "
function discard_ingredients!(player, discard_pile)
    println(player.ingredients)
    index = input_index("ingredient you wish to discard", length(player.ingredients))
    if index == false
        return false
    end
    to_discard = player.ingredients[index]
    deleteat!(player.ingredients, index)
    push!(discard_pile, to_discard)
    return true
end
" Swap out a recipe of player's choice for top recipe in `recipe_deck` "
function swap_recipes!(player, recipe_deck)
    hide_info(player.name, (player.recipes,"Your current recipes are"), false)
    index = input_index("recipe you wish to discard",length(player.recipes))
    if index == false
        return false
        hide_info(player.name, "")
    end
    to_discard = deepcopy(player.recipes[index])
    to_draw = pop!(recipe_deck)
    player.recipes[index] = to_draw
    push!(recipe_deck, to_discard)
    shuffle!(recipe_deck)
    hide_info(player.name, (player.recipes,"New recipes are"))
    return true
end
" Empties the pot into the discard pile "
function clear_pot!(pot, discard_pile)
    draw!(pot, discard_pile, length(pot))
end
" Check if list of ingredients can viably be made into specified recipe "
function is_viable_recipe(ingredients, recipe)
    indices = LinearIndices(recipe)[:]
    for ingredient in ingredients
        index = findfirst(x->recipe[x] == ingredient, indices)
        if isnothing(index)
            return false
        end
        deleteat!(indices, index)
    end
    return true
end
" Place a user-specified ingredient into a user-specified pot "
function place_ingredients!(recipes, recipe_deck, ingredient_deck, discard_pile, pots, river, players, curr_player, previous_pot)
    multiline_print(pots, "Current pots")
    println("Your ingredients: $(players[curr_player].ingredients)")
    if previous_pot > 0
        println("Note: This turn you have already placed in pot #$previous_pot.")
    end
    println()
    # Place an ingredient in a specific pot
    function get_pot_index()
        valid = false
        pot_index = -1
        while !valid
            pot_index = input_index("pot to place ingredient in",length(pots))
            if pot_index == false
                return false
            end
            if pot_index == previous_pot
                println("You just tried to place an ingredient in the same pot as earlier. Try again.")
            else
                valid = true
            end
        end
        return pot_index
    end
    pot_index = get_pot_index()
    if pot_index == false
        return false, previous_pot
    end
    index = input_index("ingredient you wish to place in pot",length(players[curr_player].ingredients))
    if index == false
        return false, previous_pot
    end
    for_pot = deepcopy(players[curr_player].ingredients[index])
    deleteat!(players[curr_player].ingredients, index)
    push!(pots[pot_index], for_pot)
    println("New pot: $(pots[pot_index])\n")
    # Now consider calling bluffs
    bluff_called = false
    result = input_line("Does any player wish to call their bluff? [y]es/[n]o")
    if result ∈ ["yes", "Yes", "y", "Y"]
        bluff_called = true
        valid = false
        bluff_index = -1
        while !valid
            player_name = input_line("Who just called the bluff?")
            for (itr, player) in enumerate(players)
                if player.name == player_name
                    if itr != curr_player
                        valid = true
                        bluff_index = itr
                    else
                        println("Only a different player can call the bluff...")
                    end
                    break
                end
            end
        end
        found_recipe = false
        for (itr,recipe) in enumerate(players[curr_player].recipes)
            if is_viable_recipe(pots[pot_index], recipe.ingredients)
                # There was no bluff - player earns their recipe
                println("\nNot a bluff! $(players[curr_player].name) had $recipe\n")
                players[curr_player].pts += recipe.pts
                new_recipe = pop!(recipe_deck)
                players[curr_player].recipes[itr] = new_recipe
                found_recipe = true
                # And pot gets cleared
                clear_pot!(pots[pot_index], discard_pile)
                break
            end
        end
        if !found_recipe
            # There was a bluff - other player steals a random recipe from bluffer
            println("\nBluff successfully called!")
            println("$(players[bluff_index].name) stole a recipe from $(players[curr_player].name)\n")
            n_recipes = length(players[curr_player].recipes)
            steal_index = rand(1:n_recipes)
            to_steal = deepcopy(players[curr_player].recipes[steal_index])
            if n_recipes == min_recipes
                new_recipe = pop!(recipe_deck)
                players[curr_player].recipes[steal_index] = new_recipe
            else
                deleteat!(players[curr_player].recipes, steal_index)
            end
            push!(players[bluff_index].recipes, to_steal)
            # And pot gets cleared
            clear_pot!(pots[pot_index], discard_pile)
        end
    elseif result ∈ ["no", "No", "n", "N"]
        # No effect if nobody calls bluff
    else
        println("Not a valid response! Assumed no.")
    end
    # Now consider claiming recipes
    if !bluff_called
        for recipe in recipes
            if sort(recipe.ingredients) == sort(pots[pot_index])
                println("This pot completed $recipe.\n")
                result = input_line("Does any player want to claim it? [y]es/[n]o")
                if result ∈ ["yes", "Yes", "y", "Y"]
                    for player in players
                        for (itr,p_recipe) in enumerate(player.recipes)
                            if p_recipe == recipe
                                # All players get their recipe points and a new recipe
                                println("$(player.name) completed this recipe")
                                player.pts += recipe.pts
                                new_recipe = pop!(recipe_deck)
                                player.recipes[itr] = new_recipe
                                break
                            end
                        end
                    end
                    # And pot gets cleared
                    clear_pot!(pots[pot_index], discard_pile)
                elseif result ∈ ["no", "No", "n", "N"]
                    # No effect if nobody claims recipe
                else
                    println("Not a valid response! Assumed no.")
                end
            end
        end
    end
    return true, pot_index
end
" Perform the 2 actions of the current player "
function next_round(recipes, recipe_deck, ingredient_deck, discard_pile, pots, river, players, curr_player)
    print_game_state(discard_pile, river, pots, players, curr_player)
    previous_pot = -1 # Cannot place two recipes in the same pot
    stones_drawn = falses(n_actions)
    curr_action = 1
    while curr_action <= n_actions
        result = input_line("Action $curr_action: [P]lace ingredient in pot,
          [D]iscard an ingredient,
          swap for a new [R]ecipe,
          [S]how all possible recipes,
          [V]iew game state,
          peek at [H]idden recipes?")
        if result ∈ ["place", "p", "P"]
            if !stones_drawn[curr_action]
                stones_drawn[curr_action] = draw_stone!(ingredient_deck, discard_pile, river, players[curr_player])
                if !stones_drawn[curr_action]
                    continue
                end
            end
            success, previous_pot = place_ingredients!(recipes, recipe_deck, ingredient_deck, discard_pile, pots, river, players, curr_player, previous_pot)
            if success
                curr_action += 1
            end
        elseif result ∈ ["discard", "d", "D"]
            if !stones_drawn[curr_action]
                stones_drawn[curr_action] = draw_stone!(ingredient_deck, discard_pile, river, players[curr_player])
                if !stones_drawn[curr_action]
                    continue
                end
            end
            if discard_ingredients!(players[curr_player], discard_pile)
                curr_action += 1
            end
        elseif result ∈ ["swap", "recipe", "Recipe", "r", "R"]
            if !stones_drawn[curr_action]
                if swap_recipes!(players[curr_player], recipe_deck)
                    curr_action += 1
                end
            else
                println("Not allowed to cancel a draw and then swap recipes!")
            end
        elseif result ∈ ["show", "Show", "s", "S"]
            multiline_print(recipes, "All recipes")
            println()
        elseif result ∈ ["view", "v", "V"]
            print_game_state(discard_pile, river, pots, players, curr_player)
        elseif result ∈ ["peek", "hidden", "Hidden", "h", "H"]
            hide_info(players[curr_player].name, (players[curr_player].recipes,"Your current recipes are"))
        else
            println("Invalid action - please try again!")
        end
    end
    return (maximum(x->x.pts, players) >= win_score)
end
" Report on stats of players - Who won? Who had which recipes? Etc "
function closing_stats(recipes, recipe_deck, ingredient_deck, discard_pile, pots, river, players, curr_player)
    winner = findfirst(x->x.pts>= win_score, players)
    if !isnothing(winner)
        println("The winner is: $(players[winner].name)!\n")
    end
    for i = 1:length(players)
        println(players[i])
        if !isnothing(winner)
            multiline_print(players[i].recipes,"with secret recipes")
        end
        println()
    end
end
" Main function for playing Stone Soup "
function play_game(num_players=2)
    @assert 2 <= num_players <= 4 "Can only play Stone Soup with an appropriate number of players!"
    game_states = init_game(num_players)
    finished = false
    while !finished
        finished = next_round(game_states...)
        # Choose next player
        game_states = merge(game_states, [:curr_player=>mod(game_states[:curr_player],num_players)+1])
    end
    closing_stats(game_states...)
end
