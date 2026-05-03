extends Node

@export var mob_scene: PackedScene
var score: int
var high_scores = HighScores.new()
const FILE_PATH = "user://dodge-the-creeps.save"



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	high_scores.from_dict(SaveFileAccess.load())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	high_scores.update_high_scores(score)
	SaveFileAccess.save({"high_scores": high_scores})
	$HUD.hide_high_score()
	$HUD.show_game_over(high_scores.top())
	$Music.stop()
	$DeathSound.play()
	
	
func new_game() -> void:
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	if not high_scores.is_empty():
		$HUD.update_high_score(high_scores.top())
	
	get_tree().call_group("mobs", "queue_free")
	
	$Music.play()


func _on_mob_timer_timeout() -> void:
	# Create a new instance of the Mob Scene
	var mob = mob_scene.instantiate()
	
	# Choose a random location on Path2D
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	
	# Set the mob's position to the random location
	mob.position = mob_spawn_location.position
	
	# Set the mob's direction perpendicular to the path direction
	var direction = mob_spawn_location.rotation + PI / 2
	
	# Add some randomness to the direction
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction
	
	# Choose the velocity for the mob
	var velocity  = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)
	
	# Spawn the mob by adding it to the Main scene
	add_child(mob)


func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
	
	
class HighScores extends RefCounted:
	var high_scores: Array[int] = []
	
	func update_high_scores(score: int) -> void:
		high_scores.sort()
		if score >= high_scores[-1]:
			high_scores.push_back(score)
		high_scores.reverse()
	
	func from_dict(dict: Dictionary) -> void:
		if "high_scores" not in dict:
			print('Saved High Scores Not Found')
		high_scores.clear()
		for num in dict.high_scores:
			high_scores.append(int(num))
		high_scores.sort()
		high_scores.reverse()
	
	func top() -> int:
		return high_scores[0]
	
	func is_empty() -> bool:
		return high_scores.size() == 0


class SaveFileAccess extends RefCounted:
	const FILE_PATH = "user://dodge-the-creeps.save"

	static func load() -> Dictionary :
		if not FileAccess.file_exists(FILE_PATH):
			print('No save file found at:', FILE_PATH)
			return {}
		
		var save_file = FileAccess.open(FILE_PATH, FileAccess.READ)
		var json_string = save_file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			printerr("Save File Parse Error:", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			return {}
		if json.data is not Dictionary:
			printerr("Save File Type Error: Expected Dictionary but got", typeof(json.data))
			return {}
	
		print("Loaded Config:", json.data)
		return json.data
	
	
	static func save(dict: Dictionary[String, Variant]) -> void:
		var save_file = FileAccess.open(FILE_PATH, FileAccess.WRITE)
		var json_string = JSON.stringify(dict, "\t")
		save_file.store_string(json_string)
		print("Saved High Scores")


	
	
	
	
	
	
	
	
	
	
	
