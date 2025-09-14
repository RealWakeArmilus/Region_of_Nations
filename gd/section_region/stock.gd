extends Control

# ---- Signals ----
#signal cell_selected(cell_id: int, cost_price: String, count: String, good_cell: VBoxContainer)


# ----- UI -----
@onready var player_node: Control = $"../../../../../.."
@onready var goods_list: HBoxContainer = $scroll/goods
@onready var good_name: Label = $good/info/name
@onready var good_type: Label = $good/info/type
@onready var good_total_count: Label = $good/warehouse/total_count/count
@onready var good_cost_price_middle_count: Label = $good/warehouse/middle_cost_price/count
@onready var buy_list: VBoxContainer = $background2/trading_glass/body/head/scroll/list/buy
@onready var sell_list: VBoxContainer = $background2/trading_glass/body/head/scroll/list/sell
@onready var market_rate: Label = $background/market_rate/count


# ---- Стабильные переменные ----
var db: SQLiteHelper
var format: Format
var current_selected_good: TextureButton = null 


func _ready() -> void:
	format = Format.new()

## Открыть раздел "Биржа"
func _on_stoke_open_pressed() -> void:
	if (player_node.info_region.stock.visible):
		return
	
	player_node.camera_2d.can_zoom = false
	player_node.info_region.body.show()
	player_node.info_region.staff_info.hide()
	player_node.info_region.production_tasks.hide()
	player_node.info_region.staff_settings.hide()
	player_node.info_region.warehouse.hide()
	player_node.info_region.stock.show()
	
	clear_node(goods_list)
	
	db = SQLiteHelper.new()
	var goods_ids = get_goods_ids_in_speciality()
	update_good_info(goods_ids['goods_product'][0])
	update_middle_cost_price_and_total_count_good(goods_ids['goods_product'][0])
	update_buy_list(goods_ids['goods_product'][0])
	update_sell_list(goods_ids['goods_product'][0])
	db.close_database()
	
	await get_tree().create_timer(0.01).timeout
	
	update_goods_list(goods_ids)
	update_market_rate_good()


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

## Обновляет данные средней себестоимости и общего количества товара на складе
func update_middle_cost_price_and_total_count_good(good_id: int):
	var good_cells = db.find_records_by_params('department_warehouse', {'company_department_id': int(player_node.info_region.data_region['department_id']), 'good_id': good_id}, ['id', 'count', 'cost_price'])
	
	var total_cost = 0.0
	var total_count = 0
	
	for cell in good_cells:
		var cell_cost_price= cell['cost_price']
		var cell_count = cell['count']
		
		total_cost += float(cell_cost_price) * int(cell_count)
		total_count += int(cell_count)
		
	if total_count > 0:
		var average_cost = total_cost / total_count
		good_cost_price_middle_count.text = format.compact_float(average_cost)
		good_total_count.text = format.compact_count(total_count)
	else:
		good_cost_price_middle_count.text = '0.0'
		good_total_count.text = '0'

## Обновляет данные по ордерам покупки товара на рынке
func update_buy_list(good_id: int):
	clear_node(buy_list)
	
	var department_orders = db.find_records_by_params('department_order', {'region_id': int(player_node.info_region.id.text), 'good_id': good_id, "type_order": 1, "status": 0})
	
	# Создаем словарь для сегментации по цене
	var orders_by_price = {}
	
	for department_order in department_orders:
		# Получаем цену ордера
		var price = department_order.get('price', 0.0)
		
		# Если для этой цены еще нет сегмента, создаем его
		if not orders_by_price.has(price):
			orders_by_price[price] = {
				'orders': [],
				'total_quantity': 0,
				'ids': []
			}
		
		# Добавляем ордер в соответствующий сегмент по цене
		orders_by_price[price]['orders'].append(department_order)
		# Суммируем количество товаров
		orders_by_price[price]['total_quantity'] += department_order.get('current_count', 0)
		# Добавляем ID ордера в список
		orders_by_price[price]['ids'].append(department_order.get('id', 0))
	
	# Сортируем цены по возрастанию (или убыванию, если нужно)
	var sorted_prices = orders_by_price.keys()
	#sorted_prices.sort()  # по возрастанию
	sorted_prices.sort_custom(func(a, b): return a > b)  # по убыванию
	
	# Находим максимальный объем среди всех групп
	var max_volume = 0
	for price in sorted_prices:
		var total_quantity = orders_by_price[price]['total_quantity']
		if total_quantity > max_volume:
			max_volume = total_quantity
	
	#print("Максимальный объем: ", max_volume)
	
	var order_number = 1
	
	# Теперь можно обрабатывать ордера, сгруппированные по цене
	for price in sorted_prices:
		await get_tree().create_timer(0.01).timeout
		
		var orders_data = orders_by_price[price]
		#var orders_at_price = orders_data['orders']
		var total_quantity = orders_data['total_quantity']
		var ids_list = orders_data['ids']
		
		#print("Цена: ", price, ", Общее количество: ", total_quantity, ", Ордеров: ", orders_at_price.size(), ", IDs: ", ids_list)
		
		# Создаем Control объект для группы
		var control_node = Control.new()
		control_node.custom_minimum_size = Vector2(356, 22)
		control_node.size = Vector2(356, 22)
		control_node.name = str(order_number)
		
		# Создаем Label для цены
		var price_label = Label.new()
		price_label.name = "price"
		price_label.text = format.compact_float(price)
		
		# Устанавливаем размер шрифта
		var font_size = 12
		price_label.add_theme_font_size_override("font_size", font_size)
		
		# Устанавливаем цвет текста #8D8777
		var text_color = Color("#8D8777")
		price_label.add_theme_color_override("font_color", text_color)
		
		# Устанавливаем выравнивание текста по левому краю
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Размещаем Label вплотную слева (позиция 0,0)
		price_label.position = Vector2(0, 0)
		price_label.size = Vector2(100, 22)
		
		# Делаем Label дочерним Control объекта
		control_node.add_child(price_label)
		
		# Рассчитываем ширину ColorRect в процентах от максимального объема
		var width_percentage = 0.0
		if max_volume > 0:
			width_percentage = float(total_quantity) / float(max_volume)
		
		# Максимальная ширина для ColorRect (можно настроить)
		var max_color_rect_width = 100.0
		var color_rect_width = max_color_rect_width * width_percentage
		
		# Создаем ColorRect для подложки
		var color_rect = ColorRect.new()
		color_rect.name = str(ids_list)
		color_rect.color = Color("#0B8600")

		# Устанавливаем размер и позицию - прижимаем к правому краю
		color_rect.size = Vector2(color_rect_width, 22)
		color_rect.position = Vector2(256 + (max_color_rect_width - color_rect_width), 0)

		# Делаем ColorRect дочерним control_node
		control_node.add_child(color_rect)

		# Создаем Label для общего количества
		var total_count_label = Label.new()
		total_count_label.name = "total_count"
		total_count_label.text = str(total_quantity)

		# Устанавливаем размер шрифта 12
		total_count_label.add_theme_font_size_override("font_size", font_size)

		# Устанавливаем цвет текста #11D200 для общего количества
		var count_color = Color("#16FF01")
		total_count_label.add_theme_color_override("font_color", count_color)

		# Устанавливаем выравнивание текста по правому краю
		total_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		total_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		# Размещаем Label справа (фиксированная позиция)
		total_count_label.position = Vector2(256, 0)
		total_count_label.size = Vector2(95, 22)

		# Делаем total_count_label дочерним control_node (а не color_rect)
		control_node.add_child(total_count_label)
		
		# Делаем Control объект дочерним для buy_list
		buy_list.add_child(control_node)
		
		order_number += 1

## Обновляет данные по ордерам продажи товара на рынке
func update_sell_list(good_id: int):
	clear_node(sell_list)
	
	var department_orders = db.find_records_by_params('department_order', {'region_id': int(player_node.info_region.id.text), 'good_id': good_id, "type_order": 0, "status": 0})
	
	# Создаем словарь для сегментации по цене
	var orders_by_price = {}
	
	for department_order in department_orders:
		# Получаем цену ордера
		var price = department_order.get('price', 0.0)
		
		# Если для этой цены еще нет сегмента, создаем его
		if not orders_by_price.has(price):
			orders_by_price[price] = {
				'orders': [],
				'total_quantity': 0,
				'ids': []
			}
		
		# Добавляем ордер в соответствующий сегмент по цене
		orders_by_price[price]['orders'].append(department_order)
		# Суммируем количество товаров
		orders_by_price[price]['total_quantity'] += department_order.get('current_count', 0)
		# Добавляем ID ордера в список
		orders_by_price[price]['ids'].append(department_order.get('id', 0))
	
	# Сортируем цены по возрастанию
	var sorted_prices = orders_by_price.keys()
	sorted_prices.sort()  # по возрастанию
	
	# Находим максимальный объем среди всех групп
	var max_volume = 0
	for price in sorted_prices:
		var total_quantity = orders_by_price[price]['total_quantity']
		if total_quantity > max_volume:
			max_volume = total_quantity
	
	var order_number = 1
	
	# Теперь можно обрабатывать ордера, сгруппированные по цене
	for price in sorted_prices:
		await get_tree().create_timer(0.01).timeout
		
		var orders_data = orders_by_price[price]
		#var orders_at_price = orders_data['orders']
		var total_quantity = orders_data['total_quantity']
		var ids_list = orders_data['ids']
		
		# Создаем Control объект для группы
		var control_node = Control.new()
		control_node.custom_minimum_size = Vector2(356, 22)
		control_node.size = Vector2(356, 22)
		control_node.name = str(order_number)
		
		# Создаем Label для цены (справа)
		var price_label = Label.new()
		price_label.name = "price"
		price_label.text = format.compact_float(price)
		
		# Устанавливаем размер шрифта
		var font_size = 12
		price_label.add_theme_font_size_override("font_size", font_size)
		
		# Устанавливаем цвет текста #8D8777 для цены
		var price_color = Color("#8D8777")
		price_label.add_theme_color_override("font_color", price_color)
		
		# Устанавливаем выравнивание текста по правому краю
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Размещаем Label справа
		price_label.position = Vector2(256, 0)
		price_label.size = Vector2(100, 22)
		
		# Делаем price_label дочерним control_node
		control_node.add_child(price_label)
		
		# Рассчитываем ширину ColorRect в процентах от максимального объема
		var width_percentage = 0.0
		if max_volume > 0:
			width_percentage = float(total_quantity) / float(max_volume)
		
		# Максимальная ширина для ColorRect (можно настроить)
		var max_color_rect_width = 100.0
		var color_rect_width = max_color_rect_width * width_percentage
		
		# Создаем ColorRect для подложки
		var color_rect = ColorRect.new()
		color_rect.name = str(ids_list)
		color_rect.color = Color("#86000B")
		
		# Устанавливаем размер и позицию - прижимаем к правому краю
		color_rect.size = Vector2(color_rect_width, 22)
		color_rect.position = Vector2(0, 0)
		
		# Делаем ColorRect дочерним control_node
		control_node.add_child(color_rect)
		
		# Создаем Label для общего количества
		var total_count_label = Label.new()
		total_count_label.name = "total_count"
		total_count_label.text = str(total_quantity)
		
		# Устанавливаем размер шрифта 12
		total_count_label.add_theme_font_size_override("font_size", font_size)
		
		# Устанавливаем цвет текста #11D200 для общего количества
		var count_color = Color("#FF1601")
		total_count_label.add_theme_color_override("font_color", count_color)
		
		# Устанавливаем выравнивание текста по правому краю
		total_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		total_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Размещаем Label справа (фиксированная позиция)
		total_count_label.position = Vector2(0, 0)
		total_count_label.size = Vector2(0, 22)
		
		# Делаем total_count_label дочерним control_node (а не color_rect)
		control_node.add_child(total_count_label)
		
		
		# Создаем Label для количества (слева)
		var count_label = Label.new()
		count_label.name = "count"
		count_label.text = str(total_quantity)
		
		# Делаем Control объект дочерним для sell_list
		sell_list.add_child(control_node)
		
		order_number += 1

## Обновление рыночного курса товара
func update_market_rate_good():
	if sell_list.get_child_count() == 0:
		market_rate.text = '0'
		print_debug('Нет ордеров продажи для обновления курса')
		return
	
	for order in sell_list.get_children():
		var price_node = order.get_node_or_null("price")
		if price_node and price_node is Label and price_node.text != "":
			market_rate.text = price_node.text
		else:
			market_rate.text = '0'
			print_debug('Ошибка: не удалось получить цену из ордера')

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
		update_middle_cost_price_and_total_count_good(good_id_selected)
		update_buy_list(good_id_selected)
		update_sell_list(good_id_selected)
		db.close_database()
		
		await get_tree().create_timer(0.01).timeout
		
		update_market_rate_good()


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
