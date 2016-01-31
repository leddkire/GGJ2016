extends Node

# Singleton class containing all common data of the player and bosses
# It is also a controller of the main scene for displaying the change of values. But it's mostly getters and setters.


# Variables ---------------------------------------------------

# Contains data from the player, that needs to be common to the whole game
var playerData={
	life=6,
	continues=4
}

var itemsQty = [0,0,0,0]

# name of the current default music. Used when a temporar music, like a boss theme or invulnerability, ends.
# It should be updated when a new chapter is loaded, since each chapter in the original game has its default theme.
var map_track="greens"

# Life of the boss, if it exists. Otherwise -1 when there's no boss.
# The life of the current boss is stored here because it needs to be displayed in the HUD.
var bossLife=-1

# Functions ----------------------------------------------------------

# --- for the player 
# removes an amount of points to the player's life and check if life is player has no more life.
func remove_player_life(amount):
	playerData.life-=amount
	if(playerData.life<=0):
		# player has no more life. Consume one continue and restore all his life.
		# Normally an animation should be played and the player restarts the level.
		restore_player_life()
		dec_player_continue()
	else:
		# player loses a bit of his life. The change must be displayed.
		_update_player_life()

# add life points to the player's life.
# Usually when the player eats a bonus item
func increase_player_life(amount):
	playerData.life+=amount
	# cap the life to the allowed maximum
	if(playerData.life>6):
		playerData.life=6
	# displays the change
	_update_player_life()

# Restore all the life points to the player
func restore_player_life():
	playerData.life=6
	# displays the change
	_update_player_life()

# tells the HUD to display the new value of player's life
func _update_player_life():
	var lifeBar=get_scene().get_nodes_in_group("lifeBar")[0]
	lifeBar.set_life(playerData.life)


func add_item_qty(texture):
	if texture == "bat_wings.png":
		_update_item(0)
	elif texture == "bear_claw.png":
		_update_item(1)
	elif texture == "tooth.png":
		_update_item(2)
	elif texture == "mushroom_icon.png" or texture == "shroom1.png" or texture == "shroom2.png" or texture == "shroom3.png":
		_update_item(3)


func _update_item(item):
	var item_obj=get_tree().get_nodes_in_group("items")[0].get_children()[item]
	itemsQty[item] += 1
	item_obj.get_node("label").set_text("x"+ str(itemsQty[item]))

func _reset_items():
	itemsQty = [0,0,0,0]
	for item in get_tree().get_nodes_in_group("items")[0].get_children():
		item.get_node("label").set_text("x0")



# --- for the boss

# setter for boss life
func set_boss_life(life):
	bossLife=life
	var lifeBar=get_scene().get_nodes_in_group("bossLifeBar")[0]
	lifeBar.set_life(bossLife)

# remove 1 point of life to boss' life
func dec_boss_life():
	bossLife-=1
	var lifeBar=get_scene().get_nodes_in_group("bossLifeBar")[0]
	lifeBar.set_life(bossLife)

# getter for boss' life
func get_boss_life():
	return bossLife

# display or hide the life of the boss in the HUD. When hidden, the score of the player is displayed instead.
func set_boss_bar_visibility(visible):
	var bossBar=get_scene().get_nodes_in_group("bossBar")[0]
	var scoreBar=get_scene().get_nodes_in_group("scoreBar")[0]
	if(visible):
		bossBar.show()
		scoreBar.hide()
	else:
		bossBar.hide()
		scoreBar.show()

# --- Various

# getter for the current default music name
func get_map_track():
	return map_track