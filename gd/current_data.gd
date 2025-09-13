extends Node

var os_data: Dictionary = {}

enum LOADING_WORLD {CREATE, CURRENT}
var status_loading_world : LOADING_WORLD

var loading_map: Array = AppData.map

var match_id: int = 1

var match_info: Dictionary = {
	"id": 1,
	"name": "world",
	"map_id": 1,
	"is_campaign": false,
	"start_time_world": "{'F': 1, 'M': 1, 'Y': 1}",  # JSON формат
	"current_time_world": "{'F': 1, 'M': 1, 'Y': 1}",  # JSON формат
	"finish_time_world": "{'F': 3, 'M': 12, 'Y': 100}",  # JSON формат
	"time_speed": 25
}

var player: Dictionary = {
	"nation_name": null
}

var isNewGame: bool = true
