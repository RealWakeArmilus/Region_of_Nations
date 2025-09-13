extends Node

signal generation_map_initialized(success: bool)

@export var regions_image: Sprite2D
@export var cities_image: Sprite2D
@export var paths_image: Sprite2D
@export var path_tscn_path: String
@onready var map_image: Sprite2D

@onready var map: Node2D
@onready var generation_map: Node
@onready var regions: Node2D
@onready var path_scene

var db: SQLiteHelper
var map_id: int

func initialize_generation():
	var start = Time.get_ticks_usec()
	db = SQLiteHelper.new("user://game_database.db")
	
	set_sprites()
	load_regions()
	load_paths()
	
	map_image.scale = Vector2(3, 3)
	regions.scale = Vector2(3, 3)
	path_scene.scale = Vector2(1, 1)
	
	db.close_database()
	emit_signal("generation_map_initialized", true)
	
	print("Время генерации: %d мкс" % (Time.get_ticks_usec() - start))


func set_sprites():
	var start = Time.get_ticks_usec()
	var match_info = (db.find_records_by_params("match_info", {"is_campaign": true}, ["map_id"], 1))[0]
	var map_info = (db.find_records_by_params("maps", {"id": match_info['map_id']}, ['id', "map_img_path", "regions_img_path", "cities_img_path", "path_tscn_path"], 1))[0]
	
	map_id = map_info['id']
	
	map = $".."
	generation_map = $"."
	regions = $"../regions"
	map_image = $"../map_image"
	
	regions_image.texture = load(map_info['regions_img_path'])
	cities_image.texture = load(map_info['cities_img_path'])
	map_image.texture = load(map_info['map_img_path'])
	path_tscn_path = map_info['path_tscn_path']
	print("Время set_sprites: %d мкс" % (Time.get_ticks_usec() - start))

func load_paths():
	var start = Time.get_ticks_usec()
	path_scene = load(path_tscn_path).instantiate()
	map.add_child.call_deferred(path_scene)
	path_scene.set_name.call_deferred('paths')
	print("Время load_paths: %d мкс" % (Time.get_ticks_usec() - start))

func load_regions():
	var start = Time.get_ticks_usec()
	
	var regions_type = []
	
	var nations_type = db.find_records('nations_type', 'map_id', map_id, [])
	for nation_type in nations_type:
		var countries_type = db.find_records('countries_type', 'nation_type_id', nation_type['id'], [])
		for country_type in countries_type:
			var provinces_type = db.find_records('provinces_type', 'country_type_id', country_type['id'], [])
			for province_type in provinces_type:
				var province_regions = db.find_records('regions_type', 'province_type_id', province_type['id'], [])
				regions_type.append_array(province_regions)
	
	var image = regions_image.get_texture().get_image()
	var pixel_color_dict = get_pixel_color_dict(image)
	var city_pixel_data = get_city_pixel_data()
	
	for region_type in regions_type:
		generation_region(region_type, image, pixel_color_dict, city_pixel_data)
	print("Время load_regions: %d мкс" % (Time.get_ticks_usec() - start))

func generation_region(region_type: Dictionary, image: Image, pixel_color_dict: Dictionary, city_pixel_data: Dictionary):
	var start = Time.get_ticks_usec()
	if not pixel_color_dict.has(region_type['color_recognition'].to_lower()):
		push_error("Цвет региона '%s' не найден на изображении!" % region_type['color_recognition'].to_lower())
		return
	
	var tscn_region = load("res://tscn/region.tscn").instantiate()
	tscn_region = set_data_region(tscn_region, region_type)
	regions.add_child(tscn_region)
	
	var polygons = get_polygons(image, region_type['color_recognition'].to_lower(), pixel_color_dict)
	
	if polygons.is_empty():
		return
	
	# Находим самый большой полигон
	var largest_polygon = null
	var max_area = 0.0
	
	for polygon in polygons:
		var area = calculate_polygon_area(polygon)
		if area > max_area:
			max_area = area
			largest_polygon = polygon
	
	if largest_polygon != null:
		# 1. Создаем VisualContainer (только для визуальных элементов)
		var visual_container = Node2D.new()
		visual_container.name = "VisualContainer"
		tscn_region.add_child(visual_container)
		
		# 2. Добавляем город в VisualContainer
		add_city_to_region(tscn_region, visual_container, pixel_color_dict[region_type['color_recognition'].to_lower()], city_pixel_data, region_type['name'])
		
		# 3. Добавляем CollisionPolygon2D
		var region_collision = CollisionPolygon2D.new()
		region_collision.polygon = largest_polygon
		tscn_region.add_child(region_collision)
		
		# 4. Добавляем Polygon2D в VisualContainer
		var region_polygon = Polygon2D.new()
		region_polygon.polygon = largest_polygon
		region_polygon.color = Color(region_type['color_view'].to_lower(), 0.15)
		visual_container.add_child(region_polygon)
		
		# 5. Настраиваем материал
		if region_polygon.material == null:
			region_polygon.material = CanvasItemMaterial.new()
			region_polygon.material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			region_polygon.material.light_mode = CanvasItemMaterial.LIGHT_MODE_NORMAL
		
		# 6. Настраиваем VisibleOnScreenNotifier2D
		var notifier = VisibleOnScreenNotifier2D.new()
		var aabb = _calculate_polygon_aabb(largest_polygon)
		notifier.position = aabb.position
		notifier.rect = Rect2(Vector2.ZERO, aabb.size)
		tscn_region.add_child(notifier)
		
		# 7. Подключаем сигналы
		_setup_notifier_signals(notifier, visual_container, region_collision, tscn_region)
		
		# 8. Центрируем позицию
		var image_size = regions_image.texture.get_size()
		visual_container.position -= image_size / 2
		region_collision.position -= image_size / 2
		notifier.position -= image_size / 2
		
		# 9. Скрываем визуальную часть
		visual_container.hide()
	print("Время generation_region: %d мкс" % (Time.get_ticks_usec() - start))

func set_data_region(tscn_region: Area2D, data_region: Dictionary) -> Area2D:
	var start = Time.get_ticks_usec()
	tscn_region.set_name(data_region['name'])
	tscn_region.data = {
		"id" : data_region['id'],
		"name": data_region['name'],
		#"flag" : JSON.parse_string(data_region['flag']),
		'department': false
	}
	
	print("Время set_data_region: %d мкс" % (Time.get_ticks_usec() - start))
	return tscn_region

# функция для получения данных городов
func get_city_pixel_data() -> Dictionary:
	var start = Time.get_ticks_usec()
	
	# Получаем изображение и конвертируем в оптимальный формат
	var image = cities_image.texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	
	# Получаем сырые данные изображения
	var data := image.get_data()
	var width := image.get_width()
	var height := image.get_height()
	var pixel_count = width * height
	
	# Создаем словарь для результатов
	var city_pixel_data = {}
	var color_cache = {}  # Кэш для быстрого доступа
	
	# Основной цикл обработки пикселей
	for i in pixel_count:
		var pos = i * 4
		# Проверка прозрачности пикселя
		if data[pos + 3] != 0:
			# Формируем цветовой ключ напрямую из байтов
			var hex = "#%02x%02x%02x" % [
				data[pos],
				data[pos + 1],
				data[pos + 2]
			]
			
			# Используем кэш для быстрого доступа к массиву координат
			var coords = color_cache.get(hex)
			if coords == null:
				coords = []
				color_cache[hex] = coords
				city_pixel_data[hex] = coords
			
			# Вычисляем координаты
			@warning_ignore("integer_division")
			coords.append(Vector2(i % width, i / width))
	
	print("Время get_city_pixel_data: %d мкс" % (Time.get_ticks_usec() - start))
	return city_pixel_data

func add_city_to_region(tscn_region: Area2D, visual_container: Node2D, region_pixels: Array, city_pixel_data: Dictionary, region_name: String):
	var start = Time.get_ticks_usec()
	# Ищем все города в пределах региона
	var cities_in_region = []
	
	# Проверяем все цвета городов (можно задать конкретный цвет)
	for city_color in city_pixel_data:
		for city_pos in city_pixel_data[city_color]:
			if region_pixels.has(city_pos):
				cities_in_region.append(city_pos)
	
	# Создаем только первый найденный город (или можно создать все)
	if cities_in_region.size() > 0:
		create_city_marker(tscn_region, visual_container, cities_in_region[0], region_name)
	else:
		# Если город не найден, создаем в центре
		var center = calculate_region_center(region_pixels)
		create_city_marker(tscn_region, visual_container, center, region_name)
		print("City not found for ", region_name, ", created at center")
	print("Время add_city_to_region: %d мкс" % (Time.get_ticks_usec() - start))

func create_city_marker(tscn_region: Area2D, visual_container: Node2D, city_position: Vector2, region_name: String) -> Node2D:
	var start = Time.get_ticks_usec()
	
	# Создаем главный контейнер для всех элементов города
	var city_container = Node2D.new()
	city_container.name = "City_" + region_name
	city_container.position = city_position
	
	# 1. Создаем визуальный маркер (ромб)
	var marker_size = 10.0
	var diamond_polygon = PackedVector2Array([
		Vector2(0, -marker_size),    # верх
		Vector2(marker_size, 0),     # право
		Vector2(0, marker_size),     # низ
		Vector2(-marker_size, 0)     # лево
	])
	
	# Визуальное представление
	var visual_marker = Polygon2D.new()
	visual_marker.name = "VisualMarker"
	visual_marker.polygon = diamond_polygon
	visual_marker.color = Color(1, 0, 0, 0.8)  # Красный с прозрачностью
	visual_marker.scale = Vector2(0.25, 0.25)
	visual_marker.z_index = 2
	city_container.add_child(visual_marker)
	
	# 2. Добавляем коллизию
	var collision_marker = CollisionPolygon2D.new()
	collision_marker.name = "Collision"
	collision_marker.polygon = diamond_polygon
	city_container.add_child(collision_marker)
	
	# 3. Добавляем подпись
	var label = Label.new()
	label.name = "CityLabel"
	label.text = region_name
	label.position = Vector2(5, -15)  # Относительно city_container
	label.scale = Vector2(0.5, 0.5)
	label.z_index = 2
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Чтобы текст не размывался при масштабировании
	label.add_theme_font_size_override("font_size", 16)
	
	city_container.add_child(label)
	
	# 4. Добавляем кнопку создания филиала
	var create_branch_button = TextureButton.new()
	create_branch_button.name = "create_branch"
	create_branch_button.texture_normal = load("res://image/icon/region/sections/create_branch.png")
	create_branch_button.position = Vector2(-12.5, -40)  # Позиция относительно city_container
	create_branch_button.ignore_texture_size = true
	create_branch_button.stretch_mode = 0
	create_branch_button.custom_minimum_size = Vector2(25, 25)
	create_branch_button.z_index = 2
	city_container.add_child(create_branch_button)
	create_branch_button.visible = false
	create_branch_button.pressed.connect(tscn_region.create_branch)
	
	# Добавляем готовый город в контейнер
	visual_container.add_child(city_container)
	
	print("Время create_city_marker: %d мкс" % (Time.get_ticks_usec() - start))
	return city_container  # Возвращаем созданный объект для дальнейшего управления

func calculate_region_center(pixels: Array) -> Vector2:
	var start = Time.get_ticks_usec()
	var center = Vector2.ZERO
	for pixel in pixels:
		center += pixel
	
	print("Время calculate_region_center: %d мкс" % (Time.get_ticks_usec() - start))
	return center / pixels.size()

# Вспомогательная функция для расчета AABB полигона
func _calculate_polygon_aabb(polygon: PackedVector2Array) -> Rect2:
	var start = Time.get_ticks_usec()
	if polygon.is_empty():
		return Rect2()
	
	var min_point = polygon[0]
	var max_point = polygon[0]
	
	for point in polygon:
		min_point.x = min(min_point.x, point.x)
		min_point.y = min(min_point.y, point.y)
		max_point.x = max(max_point.x, point.x)
		max_point.y = max(max_point.y, point.y)
		
	print("Время _calculate_polygon_aabb: %d мкс" % (Time.get_ticks_usec() - start))
	return Rect2(min_point, max_point - min_point)

func get_polygons(image: Image, region_color: String, pixel_color_dict: Dictionary) -> Array:
	var start = Time.get_ticks_usec()
	var target_image = Image.create(image.get_size().x, image.get_size().y, false, Image.FORMAT_RGBA8)
	for value in pixel_color_dict[region_color]:
		target_image.set_pixel(value.x, value.y, Color.WHITE)
	
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(target_image)
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2(0, 0), target_image.get_size()), 0.0)
	
	print("Время get_polygons: %d мкс" % (Time.get_ticks_usec() - start))
	return polygons

func _setup_notifier_signals(notifier, visual_container, region_collision, new_region):
	var start = Time.get_ticks_usec()
	
	notifier.connect("screen_entered", func():
		visual_container.show()
		region_collision.show()
		new_region.monitorable = true
		new_region.monitoring = true
	)
	
	notifier.connect("screen_exited", func():
		visual_container.hide()
		region_collision.hide()
		new_region.monitorable = false
		new_region.monitoring = false
	)
	print("Время _setup_notifier_signals: %d мкс" % (Time.get_ticks_usec() - start))

# -----------------------
# Вспомагательные функции
# -----------------------


func get_pixel_color_dict(image: Image) -> Dictionary:
	var start = Time.get_ticks_usec()
	
	# 1. Принудительно конвертируем в RGBA8 (4 байта на пиксель)
	image.convert(Image.FORMAT_RGBA8)
	
	# 2. Получаем сырые данные изображения
	var data: PackedByteArray = image.get_data()
	var width := image.get_width()
	var height := image.get_height()
	
	# 3. Создаём словарь и временный кэш для координат
	var color_dict := {}
	var coord_cache := {}  # Ключ: цвет, значение: массив координат
	
	# 4. Проходим по данным в 4 раза быстрее (без вложенных циклов)
	var pixel_count = width * height
	
	for i in pixel_count:
		var pos = i * 4
		var a = data[pos + 3]
		
		if a != 0:  # Пропускаем прозрачные пиксели
			var r = data[pos]
			var g = data[pos + 1]
			var b = data[pos + 2]
			
			# Формируем HEX-цвет БЕЗ создания строки (оптимизация)
			var hex = (r << 16) + (g << 8) + b  # Цвет как число (быстрее, чем строка)
			
			# Используем кэш для быстрого доступа
			var coords = coord_cache.get(hex, [])
			@warning_ignore("integer_division")
			coords.append(Vector2(i % width, i / width))  # Быстрое вычисление (x, y)
			coord_cache[hex] = coords
	
	# 5. Конвертируем числовые ключи обратно в HEX-строки
	for hex_num in coord_cache:
		color_dict["#%06x" % hex_num] = coord_cache[hex_num]
	
	print("Время get_pixel_color_dict: %d мкс" % (Time.get_ticks_usec() - start))
	return color_dict


# Функция для вычисления площади полигона (метод Гаусса)
func calculate_polygon_area(polygon: PackedVector2Array) -> float:
	var start = Time.get_ticks_usec()
	var area = 0.0
	var n = polygon.size()
	
	for i in range(n):
		var j = (i + 1) % n
		area += polygon[i].x * polygon[j].y
		area -= polygon[j].x * polygon[i].y
		
	print("Время calculate_polygon_area: %d мкс" % (Time.get_ticks_usec() - start))
	return abs(area) / 2.0

#
#func load_region_definitions(path: String) -> Dictionary:
	#var file = FileAccess.open(path, FileAccess.READ)
	#if file == null:
		#push_error("Failed to open regions data file: " + path)
		#return {}
	#
	#var json = JSON.parse_string(file.get_as_text())
	#if json == null:
		#push_error("JSON parse error")
		#return {}
	#
	#file.close()
	#return json
	#
