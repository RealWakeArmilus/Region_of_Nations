extends Node


'''
Ссылки на соц сети

telegram - telegram
discord - discord
'''
var telegram = 'https://t.me/DNA_of_Nation'
var discord = 'https://discord.gg/ZBjXYBnF'


'''
Ссылки на банк, для оплаты

t_bank - t_bank
'''
var t_bank = 'https://www.tinkoff.ru/rm/artemev.emil1/9JVlv1990'


'''
# Основа проекта #

project_path - относительный путь проекта. Нужен для релига
tscn - папка всех сцен
'''
#var project_path = OS.get_user_data_dir()
var tscn = 'res://tscn/'


'''
Страницы приложения:

handler - Каркас всего приложения. На нем держаться все остальные страницы.
intro - интро игры
main_menu - Главное меню приложения
campaign - компания (обучение)
loading - страница загрузки

support_project - Содержит краткое описание как поддержать проект, поэтапно.
main_settings - Настройки основных параметров приложения
create_world - страница где создается новый мир
solo_games - список одиночных игр (с возможность перейти в "create_world" и создать новый мир или загрузить уже созданный)
create_world - страница где создается новый мир
custom_game - кастомизированная одиночная игра
'''
var handler = ['handler', tscn + 'handler.tscn']
var intro = ['intro', tscn + 'intro.tscn']
var main_menu = ['main_menu', tscn + 'main_menu.tscn']
var campaign = ['campaign', tscn + 'campaign.tscn']
var loading = ['Loading', tscn + "loading.tscn"]
var map = ['map', tscn + 'map.tscn']

#func _ready():
	#print('project_path: ', project_path)
	#
	#var data_region = project_path + "/maps/1/data_match.txt"
	#print('data_region: ', data_region)


func list_directories(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Папка: ", file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Ошибка доступа к папке: ", path)

# Использование:
func _ready():
	print("Содержимое папки пользователя:")
	list_directories(OS.get_user_data_dir())
	
	print("Содержимое res://:")
	list_directories("res://")

#var support_project = ['SupportProject', tscn + 'support_project.tscn']
#var main_settings = ['MainSettings', tscn + "main_settings.tscn"]
#var solo_games = ['SoloGames', tscn + 'solo_games.tscn']
#var create_world = ['CreateWorld', tscn + 'create_world.tscn']
#var custom_game = ['CustomGame', tscn + "custom_game.tscn"]
#var player = ['Player', "res://Project/My/Scene/Subject/Player/Player.tscn"]


#'''
#Виджеты
#
#widgets = основа ссылки всех виджетов
#
#mini_menu - мини-меню, которое может использовать игрок будучи на карте
#building_categories - список всех категорий сооружний
#
#demo_view_builds - демонстрация выбраного типа сооружений
#'''
#var mini_menu = ['MiniMenu', widget +  "MiniMenu/mini_menu.tscn"]
#var mini_settings = ['MiniSettings', widget + "MiniSettings/mini_settings.tscn"]
#var building_categories = widget + "BuildingCategories/building_categories.tscn"
#var demo_view_builds = widget + "Demo_view_builds/demo_view_builds.tscn"
#var сonstructor = widget + "Сonstructor/сonstructor.tscn"


#'''
## Элементы #
#
#tile_map - текущая карта игрового мира
#'''
#@onready var tile_map : TileMap
#
#var current_player : MyPlayer
#var mouse_pos : Vector2
#var tile_mouse_pos : Vector2i
#
#
#
#'''
## SAVE WORLD #
#'''
#var path_data_world = 'user://data_world.save'
#
#func save_world():
	#var data_world = FileAccess.open(path_data_world, FileAccess.WRITE)
	#
	#var json_string = JSON.stringify(CurrentData.planet_data)
	#
	#data_world.store_line(json_string)
#
#
#func load_world():
	#if not FileAccess.file_exists(path_data_world):
		#return
	#
	#var data_world = FileAccess.open(path_data_world, FileAccess.READ)
#
	#while data_world.get_position() < data_world.get_length():
		#var json_string = data_world.get_line()
		#var json = JSON.new()
		#var _parse_result = json.parse(json_string)
		#var node_data = json.get_data()
		#
		#CurrentData.planet_data = node_data


#
#func save_world():
	#if !FileAccess.file_exists(FILE_WORLD):
		#config.set_value('planet_data', 'name_planet', CurrentData.planet_data['name_planet'][0])
		#config.set_value('planet_data', 'day', CurrentData.planet_data['date'][0]['day'])
		#config.set_value('planet_data', 'month', CurrentData.planet_data['date'][0]['month'])
		#config.set_value('planet_data', 'year', CurrentData.planet_data['date'][0]['year'])
		#
		#config.set_value('planet_data', 'landscape_seed', CurrentData.planet_data['landscape'][0]['seed'])
		#config.set_value('planet_data', 'landscape_fractal_lacunarity', CurrentData.planet_data['landscape'][0]['fractal_lacunarity'])
		#config.set_value('planet_data', 'landscape_fractal_octaves', CurrentData.planet_data['landscape'][0]['fractal_octaves'])
		#config.set_value('planet_data', 'landscape_frequency', CurrentData.planet_data['landscape'][0]['frequency'])
		#
		#config.set_value('planet_data', 'climat_seed', CurrentData.planet_data['climat'][0]['seed'])
		#config.set_value('planet_data', 'climat_fractal_lacunarity', CurrentData.planet_data['climat'][0]['fractal_lacunarity'])
		#config.set_value('planet_data', 'climat_fractal_octaves', CurrentData.planet_data['climat'][0]['fractal_octaves'])
		#config.set_value('planet_data', 'climat_frequency', CurrentData.planet_data['climat'][0]['frequency'])
		#
		#config.set_value('planet_data', 'moisture_seed', CurrentData.planet_data['moisture'][0]['seed'])
		#config.set_value('planet_data', 'moisture_fractal_lacunarity', CurrentData.planet_data['moisture'][0]['fractal_lacunarity'])
		#config.set_value('planet_data', 'moisture_fractal_octaves', CurrentData.planet_data['moisture'][0]['fractal_octaves'])
		#config.set_value('planet_data', 'moisture_frequency', CurrentData.planet_data['moisture'][0]['frequency'])
		#
		#config.set_value('planet_data', 'river_seed', CurrentData.planet_data['river'][0]['seed'])
		#config.set_value('planet_data', 'river_fractal_lacunarity', CurrentData.planet_data['river'][0]['fractal_lacunarity'])
		#config.set_value('planet_data', 'river_fractal_octaves', CurrentData.planet_data['river'][0]['fractal_octaves'])
		#config.set_value('planet_data', 'river_frequency', CurrentData.planet_data['river'][0]['frequency'])
		#
		#config.save(FILE_WORLD)


#func load_world():
	#var planet_data = {}
	#for key in config.get_section_keys('planet_data'):
		#planet_data[key] = config.get_value('planet_data', key)
	#print('load_planet_data: ', planet_data)



#'''
#Демонстрация сооружений
#
#demo_build - основа демонстрации всех сооружений
#
#residence - основа демонстрации всех сооружений, типа "Резиденции"
#
#master - сооружнение типа "Резиденции".
#'''
#var demo_build = project + 'Demo_build/'
#
#var residence = demo_build + 'Residence/'
#
#var demo_master = residence + 'master.tscn'
