extends Control

# ---- UI ----
@onready var background: TextureRect = $background
@onready var info: MarginContainer = $info
@onready var link_website = $info/links/website
@onready var link_telegram = $info/links/telegram
@onready var version: Label = $info/version
@onready var game: MarginContainer = $game
@onready var campaign: MarginContainer = $campaign
@onready var questions: VBoxContainer = $campaign/questions
@onready var nations: VBoxContainer = $campaign/nations

var db: SQLite

func _ready():
	get_game_version()
	connect_nation_buttons()

## Подключаем все кнопки наций к одному обработчику
func connect_nation_buttons():
	# Находим все TextureButton внутри nations, включая вложенные
	for child in nations.get_children():
		if child is BoxContainer:
			# Проверяем детей BoxContainer
			for grandchild in child.get_children():
				if grandchild is TextureButton:
					grandchild.pressed.connect(_on_nation_selected.bind(grandchild.name.to_lower()))
		elif child is TextureButton:
			child.pressed.connect(_on_nation_selected.bind(child.name.to_lower()))

## Проверка актуальной версии
func get_game_version():
	version.text = "v" + ProjectSettings.get_setting("application/config/version", "?.?")


# ------------------------------------
# Управление кнопками сцены handler.tscn
# ------------------------------------

func _on_website_pressed() -> void:
	OS.shell_open("https://wakeemil.pythonanywhere.com")

func _on_telegram_pressed() -> void:
	OS.shell_open("https://t.me/Supremacy1914_IMF_Channel")


# ------------------------------------
# GAME
# ------------------------------------

func _on_game_pressed() -> void:
	background.texture = load("res://image/background/4.png")
	info.visible = false
	game.visible = true

func _on_back_info_pressed() -> void:
	background.texture = load("res://image/background/2.png")
	game.visible = false
	info.visible = true


# ------------------------------------
# COMPAIGN
# ------------------------------------

func _on_campaign_pressed() -> void:
	game.visible = false
	campaign.visible = true
	CurrentData.match_id = 1
	CurrentData.match_info['is_campaign'] = true
	
	if not open_database():
		return
	
	# Проверяем существование записи о кампании
	if not check_campaign_exists():
		# Если записи нет - показываем выбор нации
		questions.visible = false
		nations.visible = true
	else:
		# Если запись есть - показываем выбор "загрузить" или "начать с начала"
		questions.visible = true
		nations.visible = false
	
	close_database()

func _on_back_game_pressed() -> void:
	campaign.visible = false
	game.visible = true
	CurrentData.match_info['is_campaign'] = false


# ------------------------------------
# COMPAIGN questions
# ------------------------------------

func _on_load_campaign_pressed() -> void:
	CurrentData.isNewGame = false
	MyButtons.from_main_menu_in_loading()

func _on_new_campaign_pressed() -> void:
	CurrentData.isNewGame = true
	questions.visible = false
	nations.visible = true

# ------------------------------------
# COMPAIGN Nation
# ------------------------------------

func _on_nation_selected(nation_name: String):
	CurrentData.player['nation_name'] = nation_name
	MyButtons.from_main_menu_in_loading()


# ------------------------------------
# DATABASE FUNCTIONS
# ------------------------------------

func open_database():
	# Инициализация базы данных
	db = SQLite.new()
	db.path = "user://game_database.db"
	db.foreign_keys = true  # Включаем поддержку внешних ключей
	
	if not db.open_db():
		push_error("Failed to open database: " + db.error_message)
		return false
	return true

func close_database():
	if db != null:
		db.close_db()
		db = null

#
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
#

func check_campaign_exists() -> bool:
	if db == null:
		push_error("Database not initialized")
		return false
	
	# 1. Проверяем существование таблицы
	if not db.query("SELECT name FROM sqlite_master WHERE type='table' AND name='match_info';"):
		push_error("Table check failed: " + db.error_message)
		return false
	
	if db.query_result.is_empty():
		# Таблицы match_info не существует
		return false
	
	# 2. Проверяем существование записи с id=1
	if not db.query("SELECT 1 FROM match_info WHERE id = 1 AND is_campaign = 1 LIMIT 1;"):
		push_error("Record check failed: " + db.error_message)
		return false
	
	# Если есть хотя бы одна запись - кампания существует
	return not db.query_result.is_empty()
