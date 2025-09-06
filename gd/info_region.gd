extends Control

# ---- UI ----
@onready var player_node = $"../.."
@onready var id = $id

@onready var name_region = $head/HBC/VBC/name_region/label
@onready var total_population = $head/HBC/VBC/total_population/details/count

@onready var body = $body

@onready var staff_info = $body/container/staff
@onready var staff_settings_button = $body/container/staff/setting
@onready var total_workers_count = $body/container/staff/total_workers/details/count
@onready var free_workers_count = $body/container/staff/free_workers/details/count
@onready var busy_workers_count = $body/container/staff/busy_workers/details/count

@onready var production_tasks = $body/container/substrates/production_tasks
@onready var staff_settings = $body/container/substrates/staff_settings
@onready var warehouse = $body/container/substrates/warehouse

@onready var basement = $basement
@onready var section_company = $basement/section_company


# ---- Заготовки экспортируемых сцен ----
var tasks_scene = preload("res://tscn/task.tscn")

# ---- Переменные ----
var db: SQLiteHelper
var data_region: Dictionary = {}

# -----------------
# Кнопки управления
# -----------------
## Закрыть регион
func _on_close_region_pressed():
	player_node.info_region.hide()
	player_node.camera_2d.can_pan = true

## Закрыть все разделы филлиала в регионе
func _on_close_all_sections_pressed():
	player_node.camera_2d.can_zoom = true
	player_node.camera_2d.can_keyboard = true
	body.hide()
	production_tasks.hide()
	staff_settings.hide()
	staff_info.hide()
	staff_settings_button.show()
	warehouse.hide()
