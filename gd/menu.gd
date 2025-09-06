extends MarginContainer

@onready var player_node = $"../.."

@onready var player_avatar: TextureRect = $head/account/player/HBC/avatar/substrate/icon
@onready var player_username: Label = $head/account/player/HBC/info/username/HBC/text
@onready var player_nation: Label = $head/account/player/HBC/info/nation/HBC/text

@onready var company_info: Panel = $head/VBoxContainer/company_info
@onready var company_avatar: TextureRect = $head/account/avatars/slot_1/avatar/icon
@onready var company_name: Label = $head/VBoxContainer/company_info/details/name/text
@onready var company_speciality: Label = $head/VBoxContainer/company_info/details/speciality/text
@onready var create_activity_button: TextureButton = $head/account/avatars/slot_1/avatar/create_activity

@onready var create_panel = $create_panel
@onready var industy_select_name = $create_panel/body/industry/select_name/text



#@onready var date: Label = $Panel/option/world_time/date/date
#@onready var phase: TextureButton = $Panel/option/world_time/phase/image
#@onready var loading_bar: TextureProgressBar = $Panel/option/world_time/phase/LoadingBar

#var db: SQLiteHelper
#var time_speed: int
#var current_time = {"F": 1, "M": 1, "Y": 1}
#var game_timer := Timer.new()
#var elapsed_seconds: int = 0

#func _ready() -> void:
	#db = SQLiteHelper.new()
	#get_player_info()
	#get_date()
	#db.close_database()
	#
	#setup_game_timer()
	#print("Game timer started: ", !game_timer.is_stopped())

#
#
#func get_date():
	#var match_info = (db.find_records_by_params('match_info', {'id': 1}, [], 1))[0]
	#time_speed = max(1, match_info['time_speed']) # Гарантируем минимум 1 секунду
	#
	#loading_bar.min_value = 0
	#loading_bar.max_value = time_speed
	#loading_bar.value = 0
	#
	#var json_string = match_info['start_time_world'].replace("'", '"')
	#current_time = JSON.parse_string(json_string)
	#update_date_label()
#
#func setup_game_timer():
	#game_timer.wait_time = 1.0  # Таймер срабатывает каждую секунду
	#game_timer.timeout.connect(_on_game_tick)
	#add_child(game_timer)
	#game_timer.start()
#
#func _on_game_tick():
	## Обновляем прогресс-бар
	#elapsed_seconds += 1
	#loading_bar.value = elapsed_seconds
	#
	## Проверяем, прошло ли достаточно времени для смены фазы
	#if elapsed_seconds >= time_speed:
		#elapsed_seconds = 0
		#loading_bar.value = 0
		#advance_game_time()
	#
	#print("Tick: ", elapsed_seconds)  # Для отладки
#
#func advance_game_time():
	#print("Advancing game time!")  # Для отладки
	#current_time['F'] += 1
	#
	## Обновляем изображение в зависимости от фазы
	#match current_time['F']:
		#2:
			#print('зарплата')
			#phase.texture_normal = load("res://image/phase/salary.png")
		#3:
			#print('потребление')
			#phase.texture_normal = load("res://image/phase/burger.png")
		#_:
			#if current_time['F'] > 3:
				#print('производство')
				#phase.texture_normal = load("res://image/phase/fabric.png")
	#
	## Обрабатываем перенос фазы
	#if current_time['F'] > 3:
		#current_time['F'] = 1
		#current_time['M'] += 1
	#
	## Обрабатываем перенос месяца
	#if current_time['M'] > 12:
		#current_time['M'] = 1
		#current_time['Y'] += 1
	#
	#print('current_time: ', current_time)
	#update_date_label()
#
#func update_date_label():
	#var phases: String = str(int(current_time['F'])).pad_zeros(2)
	#var months: String = str(int(current_time['M'])).pad_zeros(2)
	#var years: String = str(int(current_time['Y'])).pad_zeros(3)
	#
	#date.text = phases + '.' + months + '.' + years


#
# Кнопки упарвления панелью создания деятельности
#

func _on_create_activity_pressed():
	create_panel.player_data = player_node.player_data
	create_panel.visible = true

func _on_close_activity_pressed():
	create_panel.visible = false

#
# УПРАВЛЕНИЕ Кнопками меню
#

func _open_your_company_pressed() -> void:
	print('Отркыть: мой бизнес')

func _open_rating_nations_pressed() -> void:
	print('Отркыть: рейтинг наций')

func _open_tree_professions_pressed() -> void:
	print('Отркыть: дерево профессий')
	pass

func _open_setting_pressed() -> void:
	print('Отркыть: настройки')
	pass # Replace with function body.
