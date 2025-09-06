extends Control

#
# Основные модулю нода Player
#

@onready var camera_2d = $Camera2D
@onready var menu: MarginContainer = $UI/menu
@onready var info_region = $UI/info_region
@onready var tap_node: Sprite2D = $UI/tap


#
#
#

#var regions_node
#var map_image_node

var db: SQLiteHelper
var player_data: Dictionary = {}

func _ready() -> void:
	info_region_hide()
	db = SQLiteHelper.new()
	player_data = get_player_info()
	db.close_database()


#
# Скрытие всех лишних элементов UI
#

## Скрыть все лишние UI элементы info region
func info_region_hide():
	info_region.hide()
	info_region.body.hide()
	info_region.production_tasks.hide()
	info_region.staff_settings.hide()
	info_region.warehouse.hide()


#
# Возвращение данных
#

func get_player_info() -> Dictionary:
	var start = Time.get_ticks_usec()
	var player = (db.find_records_by_params('players', {'is_bot': false, 'username': CurrentData.player['username'], 'unique_id': CurrentData.player['unique_id']}, ['id', 'username', 'nation_id'], 1))[0]
	var nation = (db.find_records_by_params('nations', {'id': player['nation_id']}, ['id', 'name'], 1))[0]
	var company = db.find_records_by_params('companies', {'player_id': player['id']}, ['id', 'name', 'speciality_id'], 1)
	
	menu.player_username.text = str(player['username'])
	menu.player_nation.text = str(nation['name'])
	
	if company:
		print('Компания есть')
		company = company[0]
		company['player_id'] = player['id']
		menu.create_panel.view_new_company(company, db)
		print("Время get_player_info: %d мкс" % (Time.get_ticks_usec() - start))
		return {"id": player['id'], "username": player['username'], 'company_selected': true, 'company_id': company['id'], "nation_id": nation['id'], "nation_name": nation['name']}
	else:
		print('Компании нет')
		print("Время get_player_info: %d мкс" % (Time.get_ticks_usec() - start))
		return {"id": player['id'], "username": player['username'], 'company_selected': false, 'company_id': 0, "nation_id": nation['id'], "nation_name": nation['name']}
