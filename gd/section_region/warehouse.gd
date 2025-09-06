extends Control

# ---- Signals ----
#signal cell_selected(cell_id: int, cost_price: String, count: String, good_cell: VBoxContainer)


# ---- UI -----
@onready var player_node = $"../../../../../.."
@onready var goods_list = $goods
@onready var good_name = $good/info/name
@onready var good_type = $good/info/type
@onready var cost_price_middle_count = $good/in_warehouse/cost_price_middle/count
@onready var good_cells_list = $good/in_warehouse/cells/list


# ---- Стабильные переменные ----
var db: SQLiteHelper
var current_selected_good: TextureButton = null 

## Открыть раздел склад
func _on_warehouse_open_pressed():
	if (player_node.info_region.warehouse.visible):
		return
	
	player_node.camera_2d.can_zoom = false
	player_node.info_region.body.show()
	player_node.info_region.staff_info.hide()
	player_node.info_region.production_tasks.hide()
	player_node.info_region.staff_settings.hide()
	player_node.info_region.warehouse.show()
	
	clear_node(goods_list)
	
	db = SQLiteHelper.new()
	var goods_ids = get_goods_ids_in_speciality()
	update_good_info(goods_ids['goods_product'][0])
	update_good_cells_list(goods_ids['goods_product'][0])
	db.close_database()
	
	await get_tree().create_timer(0.01).timeout
	
	update_goods_list(goods_ids)
	update_middle_cost_price_good()


# ---- Очистка задач ----
## Полная очистка контейнера
func clear_node(node):
	for child in node.get_children():
		child.queue_free()

# ---- Возвращает данные ----
## Возвращает id товаров категории "продукт" и "материалы", которыми должен владеть компания по роду деятельности
func get_goods_ids_in_speciality() -> Dictionary:
	var company = (db.find_records('companies', 'id', player_node.player_data['company_id'], ['speciality_id'], 1))[0]
	var goods = db.find_records('goods', 'speciality_id', company['speciality_id'], [])
	var goods_task_layouts = db.get_all_records('goods_task_layouts')
	
	var goods_product: Array = []
	for good in goods:
		goods_product.append(good['id'])
	
	var goods_materials: Array = []
	for goods_task_layout in goods_task_layouts:
		for good_product in goods_product:
			if goods_task_layout['good_id'] != good_product:
				continue
			
			var material_costs = JSON.parse_string(goods_task_layout['material_costs_data'])
			
			if material_costs and material_costs.size() > 0 and material_costs[0].size() > 0:
				for material_costs_slot in material_costs:
					var material_id = int(material_costs_slot[0])
					
					if (not material_id in goods_materials) and (not material_id in goods_product):
						goods_materials.append(material_id)
	
	return {'goods_product': goods_product, 'goods_materials': goods_materials}


# ---- Обновляет данные ----
## Обновляет данные разделов товаров
func update_goods_list(goods_ids: Dictionary):
	var num: int = 0
	for good_id in goods_ids['goods_product']:
		var texture_button = TextureButton.new()
		texture_button.gui_input.connect(_on_good_gui_input.bind(texture_button))
		texture_button.custom_minimum_size = Vector2(44, 44)
		
		if num == 0:
			texture_button.texture_normal = load("res://image/substrates/button/footnot_square_white.png")
		else:
			texture_button.texture_normal = load("res://image/substrates/button/footnot_square_black.png")
		
		texture_button.name = '{0}_product'.format([int(good_id)])
		goods_list.add_child(texture_button)
		
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(44, 44)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.texture = load('res://image/icon/goods/{0}.png'.format([good_id]))
		texture_button.add_child(texture_rect)
		num += 1
	
	for good_id in goods_ids['goods_materials']:
		var texture_button = TextureButton.new()
		texture_button.gui_input.connect(_on_good_gui_input.bind(texture_button))
		texture_button.custom_minimum_size = Vector2(44, 44)
		texture_button.texture_normal = load("res://image/substrates/button/footnot_square_black.png")
		texture_button.name = '{0}_material'.format([int(good_id)])
		goods_list.add_child(texture_button)
		
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(44, 44)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.texture = load('res://image/icon/goods/{0}.png'.format([good_id]))
		texture_button.add_child(texture_rect)

## Обновляет данные товара
func update_good_info(good_id_selected: int, good_type_selected: String = ''):
	var goods = (db.find_records('goods', 'id', good_id_selected, ['name'], 1))[0]
	
	good_name.text = str(goods['name']).to_upper()
	good_type.text = 'product' if good_type_selected == '' else str(good_type_selected)

## Обновляет данные ячеек товара на складе
func update_good_cells_list(good_id: int):
	clear_node(good_cells_list)
	
	var good_cells = db.find_records_by_params('department_warehouse', {'company_department_id': int(player_node.info_region.data_region['department_id']), 'good_id': good_id}, ['id', 'count', 'cost_price'])
	
	for cell in good_cells:
		# Создаем основной контейнер
		var cell_node = VBoxContainer.new()
		cell_node.custom_minimum_size = Vector2(60, 60)
		cell_node.set("theme_override_constants/separation", 4)
		
		# Создаем панель для цены
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(60, 45)
		#panel.gui_input.connect(_on_cell_gui_input.bind(cell['id'], str(cell['cost_price']), str(cell['count']), cell_node))
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		cell_node.add_child(panel)
		
		var box = VBoxContainer.new()
		box.custom_minimum_size = Vector2(60, 45)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set("theme_override_constants/separation", 1)
		panel.add_child(box)
		
		# Создаем лейбл для цены
		var cost_price_label = Label.new()
		cost_price_label.text = str(cell['cost_price'])
		cost_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cost_price_label.add_theme_font_size_override("font_size", 12)
		cost_price_label.name = 'cost_price'
		box.add_child(cost_price_label)
		
		var title = Label.new()
		title.text = str(cell['cost_price'])
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 10)
		title.text = 'ед.'
		box.add_child(title)
		
		# Создаем лейбл для количества
		var count_label = Label.new()
		count_label.text = str(cell['count'])
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.name = 'count'
		count_label.add_theme_font_size_override("font_size", 10)
		
		var text_color = Color("#413E35")
		count_label.add_theme_color_override("font_color", text_color)
		
		cell_node.add_child(count_label)
		
		# Добавляем созданную ячейку в good_cells_list
		cell_node.name = str(cell['id'])
		good_cells_list.add_child(cell_node)

## Обновляем среднею себестоимость товара исходя из всех ячеек на складе
func update_middle_cost_price_good():
	var total_cost = 0.0
	var total_count = 0
	
	for cell in good_cells_list.get_children():
		var panel = cell.get_child(0)
		var box = panel.get_child(0)
		var cost_price_label = box.get_child(0)
		var count_label = cell.get_child(1)
		
		total_cost += float(cost_price_label.text) * int(count_label.text)
		total_count += int(count_label.text)
	
	if total_count > 0:
		var average_cost = total_cost / total_count
		cost_price_middle_count.text = str(average_cost)
	else:
		cost_price_middle_count.text = '0.0'

## Функция для визуального выделения выбранного товара
func update_selected_good_visual(selected_good: TextureButton):
	# Сбрасываем все кнопки к черной текстуре
	for child in goods_list.get_children():
		if child is TextureButton:
			child.texture_normal = load("res://image/substrates/button/footnot_square_black.png")
	
	# Устанавливаем белую текстуру для выбранного товара
	selected_good.texture_normal = load("res://image/substrates/button/footnot_square_white.png")
	
	# Обновляем текущий выбранный товар
	current_selected_good = selected_good


# ---- Обработчики ----
## Обработчик клика по разделу товара
func _on_good_gui_input(event: InputEvent, good_node: TextureButton):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_texture_button_path(good_node) == "res://image/substrates/button/footnot_square_white.png":
			return
		
		update_selected_good_visual(good_node)
		
		var object_name = str(good_node.name)
		var parts = object_name.split("_")
		var good_id_selected = int(parts[0])
		var good_type_selected = parts[1]
		
		db = SQLiteHelper.new()
		update_good_info(good_id_selected, good_type_selected)
		update_good_cells_list(good_id_selected)
		db.close_database()
		
		await get_tree().create_timer(0.01).timeout
		
		update_middle_cost_price_good()

### Обработчик клика по ячейки товара на складе
#func _on_cell_gui_input(event: InputEvent, cell_id: int, cost_price: String, count: String, good_cell: VBoxContainer):
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#cell_selected.emit(cell_id, cost_price, count, good_cell)


# ---- Вспомагательные функции
# Создаем вспомогательную функцию
func get_texture_button_path(texture_button: TextureButton) -> String:
	if texture_button.texture_normal != null and texture_button.texture_normal.resource_path != "res://image/point.png":
		return texture_button.texture_normal.resource_path
	return ''
