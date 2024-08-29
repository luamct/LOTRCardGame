extends Node

var cards: Dictionary = Dictionary()
const resources_path: String = "res://assets/resources/cards/"

func _ready():
	for set_folder in DirAccess.get_directories_at(resources_path):
		var set_folder_path := resources_path + set_folder
		print("Loading cards at: ", set_folder_path)
		for file_name in DirAccess.get_files_at(set_folder_path):
			var file_path : String = set_folder_path + "/" + file_name
			var resource: CardData = load(file_path)
			cards[resource.name] = resource
