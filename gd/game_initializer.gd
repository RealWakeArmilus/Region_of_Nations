extends Node

@onready var game_initializer: Node = $"."
@onready var default_data: Node = $"../default_data"
@onready var generation_map: Node = $"../generation_map"
@onready var database_manager: Node = $"../database_manager"
@onready var sprites: Node2D = $"../sprites"

var db : SQLiteHelper

func _ready():
	var start = Time.get_ticks_usec()
	if CurrentData.isNewGame:
		_init_database()
	else:
		_init_generation_map()
	print("Время game_initializer: %d мкс" % (Time.get_ticks_usec() - start))


## Запуск инициализации базы данных
func _init_database():
	database_manager.connect("database_initialized", _check_database_initialized)
	database_manager.initialize_database()


## Запускаем генерацию карты
func _init_generation_map():
	generation_map.connect("generation_map_initialized", _check_generation_map)
	generation_map.initialize_generation()


## Проверка сигнала после инициализации базы данных
func _check_database_initialized(success: bool):
	if success:
		print("База данных успешно инициализирована!")
		# Здесь можно продолжать загрузку игры
		_init_generation_map()
	else:
		print("Ошибка инициализации базы данных!")
		# Здесь можно показать сообщение об ошибке
		#show_error_message()

## Проверка сигнала после генерации карты
func _check_generation_map(success: bool):
	if success:
		print("Карта успешно сгенерирована!")
		# Здесь можно продолжать загрузку игры
		default_data.queue_free()
		generation_map.queue_free()
		database_manager.queue_free()
		sprites.queue_free()
		self.queue_free()
	else:
		print("Ошибка генерации карты!")
		# Здесь можно показать сообщение об ошибке
		#show_error_message()
