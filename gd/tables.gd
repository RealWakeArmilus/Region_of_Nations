extends Node



## Словарь с определением всех таблиц базы данных
const TABLE_DEFINITIONS = {
	"maps": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"map_img_path": {"data_type": "text"},
		"regions_txt_path": {"data_type": "text"},
		"regions_img_path": {"data_type": "text"},
		"cities_img_path": {"data_type": "text"},
		"path_tscn_path": {"data_type": "text"}
	},
	
	"match_info": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"map_id": {"data_type": "int", "not_null": true, "foreign_key": "maps.id"},
		"is_campaign": {"data_type": "bool", "not_null": true},
		"start_time_world": {"data_type": "text", "not_null": true},  # JSON формат
		"current_time_world": {"data_type": "text", "not_null": true},  # JSON формат
		"finish_time_world": {"data_type": "text", "not_null": true},  # JSON формат
		"time_speed": {"data_type": "int", "not_null": true, "default": 20},
		"passing_time": {"data_type": "bool", "not_null": true}, # Ход времени: 0 - 10_000-0+ до нашей эры ; 1 - 0-10_000+ наша эра
	},
	
	"nations": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"match_id": {"data_type": "int", "not_null": true, "foreign_key": "match_info.id"},
		"rating_rate": {"data_type": "real", "not_null": true, "default": 0.0},
		"population_ratio": {"data_type": "real", "not_null": true, "default": 0.0},
		"capital_ratio": {"data_type": "real", "not_null": true, "default": 0.0},
		"employment_rate": {"data_type": "real", "not_null": true, "default": 0.0},
		"professional_rate": {"data_type": "real", "not_null": true, "default": 0.0}
	},
	
	"players": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"is_bot": {"data_type": "bool", "not_null": true, "default": true},
		"unique_id": {"data_type": "text", "not_null": true},
		"username": {"data_type": "text", "not_null": true},
		"nation_id": {"data_type": "int", "foreign_key": "nations.id"},
		"is_expansion_of_power": {"data_type": "bool", "not_null": true, "default": false},
		"budget": {"data_type": "real", "not_null": true, "default": 50_000.0}
	},
	
	"nations_effects_type": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"required_points": {"data_type": "int", "not_null": true},
		"learn": {"data_type": "bool", "not_null": true, "default": true}
	},
	
	"nations_effects": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"nation_effects_type_id": {"data_type": "int", "not_null": true, "foreign_key": "nations_effects_type.id"},
		"nation_id": {"data_type": "int", "not_null": true, "foreign_key": "nations.id"},
		"received_points": {"data_type": "int", "not_null": true, "default": 0},
		"open": {"data_type": "bool", "not_null": true, "default": false}
	},
	
	"industries": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true}
	},
	
	"specializations": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"industry_id": {"data_type": "int", "not_null": true, "foreign_key": "industries.id"}
	},
	
	"professions_type": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"speciality_id": {"data_type": "int", "foreign_key": "specializations.id"},
		"required_points": {"data_type": "int", "not_null": true},
		"required_professions": {"data_type": "text"},  # JSON формат
		"learn": {"data_type": "bool", "not_null": true, "default": true}
	},
	
	"categories_goods": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true}
	},
	
	"countries": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"player_id": {"data_type": "int", "foreign_key": "players.id"}
	},
	
	"provinces": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"player_id": {"data_type": "int", "foreign_key": "players.id"},
		"country_id": {"data_type": "int", "not_null": true, "foreign_key": "countries.id"},
		"salary_fix": {"data_type": "real", "not_null": true, "default": 100.0}
	},
	
	"regions": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"color_recognition": {"data_type": "text", "not_null": true},  # Формат #RRGGBB
		"color_view": {"data_type": "text", "not_null": true},  # Формат #RRGGBB
		"flag": {"data_type": "text"},
		"budget": {"data_type": "real", "not_null": true, "default": 1_000_000.0},
		"province_id": {"data_type": "int", "not_null": true, "foreign_key": "provinces.id"}
	},
	
	"professions": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"profession_type_id": {"data_type": "int", "not_null": true, "foreign_key": "professions_type.id"},
		"country_id": {"data_type": "int", "not_null": true, "foreign_key": "countries.id"},
		"received_points": {"data_type": "int", "not_null": true, "default": 0},
		"open": {"data_type": "bool", "not_null": true, "default": false}
	},
	
	"goods": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"category_goods_id": {"data_type": "int", "not_null": true, "foreign_key": "categories_goods.id"},
		"speciality_id": {"data_type": "int", "not_null": true, "foreign_key": "specializations.id"},
		"name": {"data_type": "text", "not_null": true}
	},
	
	"goods_task_layouts": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"good_id": {"data_type": "int", "not_null": true, "foreign_key": "goods.id"},
		"production_volume": {"data_type": "int", "not_null": true, "default": 0},
		"material_costs_data": {"data_type": "text"}, # JSON [['good_id', 'count']
		"busy_workers_data": {"data_type": "text"}, # JSON [['profession_id', 'count']
		"period_production": {"data_type": "int", "not_null": true, "default": 0}
	},
	
	"population_groups": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"region_id": {"data_type": "int", "not_null": true, "foreign_key": "regions.id"},
		"nation_id": {"data_type": "int", "not_null": true, "foreign_key": "nations.id"},
		"profession_type_id": {"data_type": "int", "foreign_key": "professions_type.id"},
		"total_people": {"data_type": "int", "not_null": true},
		"budget": {"data_type": "real", "not_null": true, "default": 50_000.0}
	},
	
	"companies": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"name": {"data_type": "text", "not_null": true},
		"player_id": {"data_type": "int", "foreign_key": "players.id"},
		"speciality_id": {"data_type": "int", "foreign_key": "specializations.id"}
	},
	
	"company_departments": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"company_id": {"data_type": "int", "not_null": true, "foreign_key": "companies.id"},
		"region_id": {"data_type": "int", "not_null": true, "foreign_key": "regions.id"},
		"total_workers": {"data_type": "int", "not_null": true, "default": 0},
		"budget": {"data_type": "real", "not_null": true, "default": 0.0},
		"salary": {"data_type": "real", "not_null": true, "default": 100.0},
	},
	
	"department_warehouse": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		'company_department_id': {"data_type": "int", "not_null": true, "foreign_key": "company_departments.id"},
		'good_id': {"data_type": "int", "not_null": true, "foreign_key": "goods.id"},
		'count': {"data_type": "int", "not_null": true, "default": 0},
		'cost_price': {"data_type": "real", "not_null": true, "default": 0.0}
	},
	
	"department_tasks": {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true, "not_null": true},
		"company_department_id": {"data_type": "int", "not_null": true, "foreign_key": "company_departments.id"},
		"good_id": {"data_type": "int", "not_null": true, "foreign_key": "goods.id"},
		"material_costs_data": {"data_type": "text"}, # JSON [{'stock_id': id, 'icon': id, 'count': int, 'cost_price': flot}]
		"busy_workers_data": {"data_type": "text"}, # JSON [{'icon': id, 'count': int}]
		"salary_to_task": {"data_type": "real", "not_null": true, "default": 0.0},
		"period_production": {"data_type": "int", "not_null": true, "default": 0},
		"production_volume": {"data_type": "real", "not_null": true, "default": 0.0},
		"product_cost_price": {"data_type": "real", "not_null": true, "default": 0.0},
		"start_production": {"data_type": "text"}, # JSON TIME
		"ent_production": {"data_type": "text"}, # JSON TIME
		"status": {"data_type": "bool", "not_null": true, "default": false} # True - завершено, False - в процессе
	}
}


## Статичные данные для инициализации таблиц
const STATIC_DATA = {
	"maps": [
		{"id": 1, "name": "Birth of the Roman Empire", "map_img_path": "res://maps/1/map.png", "regions_txt_path": "res://maps/1/regions.txt", "regions_img_path": "res://maps/1/regions.png", "cities_img_path": "res://maps/1/cities.png", "path_tscn_path": "res://maps/1/paths.tscn"}
	],
	"match_info": [
		{"id": 1, "name": "Birth of the Roman Empire", "map_id": 1, "is_campaign": 1, "start_time_world": "{'F': 1, 'M': 1, 'Y': 1}", "current_time_world": "{'F': 1, 'M': 1, 'Y': 1}", "finish_time_world": "{'F': 3, 'M': 12, 'Y': 100}", "time_speed": 20, "passing_time": 0}
	],
	"nations_effects_type": [
		{"id": 1, "name": "язык", "required_points": 0, "learn": 1}, 
		{"id": 2, "name": "Рост мышц", "required_points": 1000, "learn": 1}, 
		{"id": 3, "name": "Интеллект", "required_points": 1000, "learn": 1} # Снижает цену, на 
	],
	"industries": [
		{"id": 1, "name": "default"},
		{"id": 2, "name": "добыча"},
		{"id": 3, "name": "обработка"},
		{"id": 4, "name": "производство"}
	],
	"specializations": [
		{"id": 1, "name": "default", "industry_id": 1},
		{"id": 2, "name": "лесное дело", "industry_id": 2},
		{"id": 3, "name": "горная добыча", "industry_id": 2},
		{"id": 4, "name": "шахтерство", "industry_id": 2},
		{"id": 5, "name": "сельское хозяйство", "industry_id": 2},
		{"id": 6, "name": "обработка", "industry_id": 3},
		{"id": 7, "name": "пекарня", "industry_id": 4},
		{"id": 8, "name": "ателье", "industry_id": 4},
		{"id": 9, "name": "литейная", "industry_id": 3},
		{"id": 10, "name": "кузня", "industry_id": 4},
		{"id": 11, "name": "тележное дело", "industry_id": 4}
	],
	"professions_type": [
		{"id": 1, "name": "без образования", "speciality_id": 1, "required_points": 0, "required_professions": '[]', "learn": true},
		{"id": 2, "name": "лесоруб", "speciality_id": 2, "required_points": 50, "required_professions": '[1]', "learn": true},
		{"id": 3, "name": "каменщик", "speciality_id": 3, "required_points": 50, "required_professions": '[1]', "learn": true},
		{"id": 4, "name": "шахтер", "speciality_id": 4, "required_points": 150, "required_professions": '[2]', "learn": true},
		{"id": 5, "name": "плантатор", "speciality_id": 5, "required_points": 150, "required_professions": '[2]', "learn": true},
		{"id": 6, "name": "обработчик", "speciality_id": 6, "required_points": 200, "required_professions": '[5]', "learn": true},
		{"id": 7, "name": "пекарь", "speciality_id": 7, "required_points": 250, "required_professions": '[5]', "learn": true},
		{"id": 8, "name": "прядильщик", "speciality_id": 8, "required_points": 250, "required_professions": '[6]', "learn": true},
		{"id": 9, "name": "литейщик", "speciality_id": 9, "required_points": 250, "required_professions": '[6]', "learn": true},
		{"id": 10, "name": "кузнец", "speciality_id": 10, "required_points": 500, "required_professions": '[9]', "learn": true},
		{"id": 11, "name": "тележник", "speciality_id": 11, "required_points": 400, "required_professions": '[10]', "learn": true},
		{"id": 12, "name": "скоро...", "speciality_id": 1, "required_points": 0, "required_professions": '[11]', "learn": false},
	],
	"categories_goods": [
		{"id": 1, "name": "сырьё"},
		{"id": 2, "name": "материалы"},
		{"id": 3, "name": "инструменты"},
		{"id": 4, "name": "еда"},
		{"id": 5, "name": "одежда"},
		{"id": 6, "name": "оружие"},
		{"id": 7, "name": "транспорт"},
		{"id": 8, "name": "деньги"}
	],
	"goods": [
		{"id": 0, "category_goods_id": 8, "speciality_id": 1, "name": "деньги"},
		{"id": 1, "category_goods_id": 1, "speciality_id": 2, "name": "дерево"},
		{"id": 2, "category_goods_id": 1, "speciality_id": 2, "name": "семена"},
		{"id": 3, "category_goods_id": 1, "speciality_id": 3, "name": "камень"},
		{"id": 4, "category_goods_id": 1, "speciality_id": 3, "name": "глина"},
		{"id": 5, "category_goods_id": 1, "speciality_id": 4, "name": "олово"},
		{"id": 6, "category_goods_id": 1, "speciality_id": 4, "name": "медь"},
		{"id": 7, "category_goods_id": 1, "speciality_id": 4, "name": "золото"},
		{"id": 8, "category_goods_id": 1, "speciality_id": 5, "name": "пшеница"},
		{"id": 9, "category_goods_id": 1, "speciality_id": 5, "name": "хлопок"},
		{"id": 10, "category_goods_id": 2, "speciality_id": 6, "name": "древесина"},
		{"id": 11, "category_goods_id": 2, "speciality_id": 6, "name": "рунит"},
		{"id": 12, "category_goods_id": 2, "speciality_id": 6, "name": "палки"},
		{"id": 13, "category_goods_id": 3, "speciality_id": 6, "name": "инструменты"},
		{"id": 14, "category_goods_id": 6, "speciality_id": 6, "name": "лук"},
		{"id": 15, "category_goods_id": 2, "speciality_id": 7, "name": "мука"},
		{"id": 16, "category_goods_id": 4, "speciality_id": 7, "name": "хлеб"},
		{"id": 17, "category_goods_id": 2, "speciality_id": 8, "name": "хлопковая нить"},
		{"id": 18, "category_goods_id": 2, "speciality_id": 8, "name": "хлопковая ткань"},
		{"id": 19, "category_goods_id": 5, "speciality_id": 8, "name": "хлопковая одежда"},
		{"id": 20, "category_goods_id": 2, "speciality_id": 9, "name": "слитка из олова"},
		{"id": 21, "category_goods_id": 2, "speciality_id": 9, "name": "слитка из меди"},
		{"id": 22, "category_goods_id": 2, "speciality_id": 9, "name": "слитка из бронзы"},
		{"id": 23, "category_goods_id": 2, "speciality_id": 9, "name": "слитка из золота"},
		{"id": 24, "category_goods_id": 2, "speciality_id": 10, "name": "заготовки из бронзы"},
		{"id": 25, "category_goods_id": 2, "speciality_id": 10, "name": "заготовки из золота"},
		{"id": 26, "category_goods_id": 6, "speciality_id": 10, "name": "копьё"},
		{"id": 27, "category_goods_id": 3, "speciality_id": 10, "name": "прочные инструменты"},
		{"id": 28, "category_goods_id": 6, "speciality_id": 10, "name": "меч"},
		{"id": 29, "category_goods_id": 6, "speciality_id": 10, "name": "нагрудник"},
		{"id": 30, "category_goods_id": 2, "speciality_id": 11, "name": "колеса"},
		{"id": 31, "category_goods_id": 7, "speciality_id": 11, "name": "тележка"},
		{"id": 32, "category_goods_id": 7, "speciality_id": 11, "name": "колесница"},
		{"id": 34, "category_goods_id": 2, "speciality_id": 8, "name": "хлопковый мешок"},
	],
	"goods_task_layouts": [
		{"id": 1, "good_id": 1, "production_volume": 5, "material_costs_data": '[[]]', "busy_workers_data": '[[2, 1]]', "period_production": 1},
		{"id": 2, "good_id": 1, "production_volume": 30, "material_costs_data": '[[13, 2]]', "busy_workers_data": '[[2, 1]]', "period_production": 1},
		{"id": 3, "good_id": 1, "production_volume": 90, "material_costs_data": '[[27, 1]]', "busy_workers_data": '[[2, 1]]', "period_production": 1},
		{"id": 4, "good_id": 2, "production_volume": 10, "material_costs_data": '[[]]', "busy_workers_data": '[[2, 1]]', "period_production": 1},
		{"id": 5, "good_id": 2, "production_volume": 60, "material_costs_data": '[[13, 2]]', "busy_workers_data": '[[2, 1]]', "period_production": 1},
		{"id": 6, "good_id": 2, "production_volume": 120, "material_costs_data": '[[27, 1]]', "busy_workers_data": '[[2, 1]]', "period_production": 1},
		{"id": 7, "good_id": 3, "production_volume": 10, "material_costs_data": '[[]]', "busy_workers_data": '[[3, 1]]', "period_production": 1},
		{"id": 8, "good_id": 3, "production_volume": 30, "material_costs_data": '[[13, 2]]', "busy_workers_data": '[[3, 1]]', "period_production": 1},
		{"id": 9, "good_id": 3, "production_volume": 50, "material_costs_data": '[[27, 1]]', "busy_workers_data": '[[3, 1]]', "period_production": 1},
		{"id": 10, "good_id": 4, "production_volume": 10, "material_costs_data": '[[]]', "busy_workers_data": '[[3, 1]]', "period_production": 1},
		{"id": 11, "good_id": 4, "production_volume": 45, "material_costs_data": '[[13, 2]]', "busy_workers_data": '[[3, 1]]', "period_production": 1},
		{"id": 12, "good_id": 4, "production_volume": 90, "material_costs_data": '[[27, 1]]', "busy_workers_data": '[[3, 1]]', "period_production": 1},
		{"id": 13, "good_id": 5, "production_volume": 6, "material_costs_data": '[[]]', "busy_workers_data": '[[3, 1]]', "period_production": 1},
		{"id": 14, "good_id": 5, "production_volume": 18, "material_costs_data": '[[13, 2]]', "busy_workers_data": '[[4, 1]]', "period_production": 1},
		{"id": 15, "good_id": 5, "production_volume": 24, "material_costs_data": '[[27, 1]]', "busy_workers_data": '[[4, 1]]', "period_production": 1},
		{"id": 16, "good_id": 6, "production_volume": 3, "material_costs_data": '[[]]', "busy_workers_data": '[[4, 1]]', "period_production": 1},
		{"id": 17, "good_id": 6, "production_volume": 22, "material_costs_data": '[[13, 2]]', "busy_workers_data": '[[4, 1]]', "period_production": 1},
		{"id": 18, "good_id": 6, "production_volume": 28, "material_costs_data": '[[27, 1]]', "busy_workers_data": '[[4, 1]]', "period_production": 1},
		{"id": 19, "good_id": 7, "production_volume": 3, "material_costs_data": '[[]]', "busy_workers_data": '[[4, 1]]', "period_production": 1},
		{"id": 20, "good_id": 7, "production_volume": 7, "material_costs_data": '[[13, 2]]', "busy_workers_data": '[[4, 1]]', "period_production": 1},
		{"id": 21, "good_id": 7, "production_volume": 16, "material_costs_data": '[[27, 1]]', "busy_workers_data": '[[4, 1]]', "period_production": 1},
		{"id": 22, "good_id": 8, "production_volume": 90, "material_costs_data": '[[2, 30]]', "busy_workers_data": '[[5, 1]]', "period_production": 12},
		{"id": 23, "good_id": 8, "production_volume": 120, "material_costs_data": '[[2, 30], [13, 2]]', "busy_workers_data": '[[5, 1]]', "period_production": 12},
		{"id": 24, "good_id": 8, "production_volume": 150, "material_costs_data": '[[2, 30], [27, 1]]', "busy_workers_data": '[[5, 1]]', "period_production": 12},
		{"id": 25, "good_id": 9, "production_volume": 60, "material_costs_data": '[[2, 30]]', "busy_workers_data": '[[5, 1]]', "period_production": 12},
		{"id": 26, "good_id": 9, "production_volume": 70, "material_costs_data": '[[2, 30], [13, 2]]', "busy_workers_data": '[[5, 1]]', "period_production": 12},
		{"id": 27, "good_id": 9, "production_volume": 80, "material_costs_data": '[[2, 30], [27, 1]]', "busy_workers_data": '[[5, 1]]', "period_production": 12},
		{"id": 28, "good_id": 10, "production_volume": 337, "material_costs_data": '[[1, 1]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 29, "good_id": 10, "production_volume": 474, "material_costs_data": '[[1, 1], [13, 2]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 30, "good_id": 10, "production_volume": 500, "material_costs_data": '[[1, 1], [27, 1]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 31, "good_id": 11, "production_volume": 10, "material_costs_data": '[[3, 1]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 32, "good_id": 11, "production_volume": 50, "material_costs_data": '[[3, 1], [13, 4]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 33, "good_id": 11, "production_volume": 100, "material_costs_data": '[[3, 1], [27, 2]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 34, "good_id": 12, "production_volume": 20, "material_costs_data": '[[10, 10]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 35, "good_id": 12, "production_volume": 40, "material_costs_data": '[[10, 20], [13, 2]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 36, "good_id": 12, "production_volume": 60, "material_costs_data": '[[10, 30], [27, 1]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 37, "good_id": 13, "production_volume": 10, "material_costs_data": '[[12, 10], [11, 10]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 38, "good_id": 13, "production_volume": 30, "material_costs_data": '[[12, 30], [11, 30], [13, 2]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 39, "good_id": 13, "production_volume": 60, "material_costs_data": '[[12, 60], [11, 60], [27, 1]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 40, "good_id": 14, "production_volume": 6, "material_costs_data": '[[12, 6], [17, 6]]', "busy_workers_data": '[[6, 1]]', "period_production": 2},
		{"id": 41, "good_id": 14, "production_volume": 6, "material_costs_data": '[[12, 6], [17, 6], [13, 2]]', "busy_workers_data": '[[6, 1]]', "period_production": 1},
		{"id": 42, "good_id": 14, "production_volume": 18, "material_costs_data": '[[12, 18], [17, 18], [27, 1]]', "busy_workers_data": '[[6, 1]]', "period_production": 2},
		{"id": 43, "good_id": 15, "production_volume": 60, "material_costs_data": '[[8, 300], [34, 60]]', "busy_workers_data": '[[7, 2]]', "period_production": 1},
		{"id": 44, "good_id": 15, "production_volume": 90, "material_costs_data": '[[8, 450], [34, 90], [13, 4]]', "busy_workers_data": '[[7, 2]]', "period_production": 1},
		{"id": 45, "good_id": 15, "production_volume": 200, "material_costs_data": '[[8, 1000], [34, 200], [27, 2]]', "busy_workers_data": '[[7, 2]]', "period_production": 1},
		{"id": 46, "good_id": 16, "production_volume": 600, "material_costs_data": '[[15, 100], [13, 2]]', "busy_workers_data": '[[7, 2]]', "period_production": 1},
		{"id": 47, "good_id": 16, "production_volume": 1400, "material_costs_data": '[[15, 200], [27, 2]]', "busy_workers_data": '[[7, 2]]', "period_production": 1},
		{"id": 48, "good_id": 17, "production_volume": 800, "material_costs_data": '[[9, 10]]', "busy_workers_data": '[[8, 1]]', "period_production": 1},
		{"id": 49, "good_id": 17, "production_volume": 8000, "material_costs_data": '[[9, 100], [13, 2]]', "busy_workers_data": '[[8, 2]]', "period_production": 1},
		{"id": 50, "good_id": 17, "production_volume": 24_000, "material_costs_data": '[[9, 300], [27, 1]]', "busy_workers_data": '[[8, 2]]', "period_production": 1},
		{"id": 51, "good_id": 18, "production_volume": 10, "material_costs_data": '[[17, 10000], [13, 2]]', "busy_workers_data": '[[8, 1]]', "period_production": 1},
		{"id": 52, "good_id": 18, "production_volume": 15, "material_costs_data": '[[17, 15000], [27, 1]]', "busy_workers_data": '[[8, 1]]', "period_production": 1},
		{"id": 53, "good_id": 19, "production_volume": 10, "material_costs_data": '[[18, 5], [13, 26]]', "busy_workers_data": '[[8, 1]]', "period_production": 3},
		{"id": 54, "good_id": 19, "production_volume": 20, "material_costs_data": '[[18, 10], [27, 51]]', "busy_workers_data": '[[8, 1]]', "period_production": 2},
		{"id": 55, "good_id": 20, "production_volume": 20, "material_costs_data": '[[5, 2], [13, 10]]', "busy_workers_data": '[[9, 1]]', "period_production": 1},
		{"id": 56, "good_id": 20, "production_volume": 200, "material_costs_data": '[[5, 20], [27, 2]]', "busy_workers_data": '[[9, 1]]', "period_production": 1},
		{"id": 57, "good_id": 21, "production_volume": 20, "material_costs_data": '[[6, 2], [13, 10]]', "busy_workers_data": '[[9, 1]]', "period_production": 1},
		{"id": 58, "good_id": 21, "production_volume": 200, "material_costs_data": '[[6, 2], [27, 2]]', "busy_workers_data": '[[9, 1]]', "period_production": 1},
		{"id": 59, "good_id": 22, "production_volume": 20, "material_costs_data": '[[20, 10], [21, 10], [27, 2]]', "busy_workers_data": '[[9, 1]]', "period_production": 1},
		{"id": 60, "good_id": 23, "production_volume": 20, "material_costs_data": '[[7, 2], [27, 2]]', "busy_workers_data": '[[9, 1]]', "period_production": 1},
		{"id": 61, "good_id": 24, "production_volume": 20, "material_costs_data": '[[22, 10], [13, 10]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 62, "good_id": 24, "production_volume": 20, "material_costs_data": '[[22, 10], [27, 1]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 63, "good_id": 25, "production_volume": 20, "material_costs_data": '[[23, 10], [13, 10]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 64, "good_id": 25, "production_volume": 20, "material_costs_data": '[[23, 10], [27, 1]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 65, "good_id": 26, "production_volume": 10, "material_costs_data": '[[12, 10], [11, 10]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 66, "good_id": 26, "production_volume": 28, "material_costs_data": '[[12, 28], [11, 28], [13, 2]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 67, "good_id": 26, "production_volume": 50, "material_costs_data": '[[12, 50], [11, 50], [27, 1]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 68, "good_id": 27, "production_volume": 10, "material_costs_data": '[[12, 10], [24, 5]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 69, "good_id": 27, "production_volume": 28, "material_costs_data": '[[12, 28], [24, 14], [13, 2]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 70, "good_id": 27, "production_volume": 50, "material_costs_data": '[[12, 50], [24, 25], [27, 1]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 71, "good_id": 28, "production_volume": 10, "material_costs_data": '[[12, 10], [24, 5]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 72, "good_id": 28, "production_volume": 28, "material_costs_data": '[[12, 28], [24, 14], [13, 2]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 73, "good_id": 28, "production_volume": 50, "material_costs_data": '[[12, 50], [24, 25], [27, 1]]', "busy_workers_data": '[[10, 1]]', "period_production": 1},
		{"id": 74, "good_id": 29, "production_volume": 1, "material_costs_data": '[[24, 10], [17, 20]]', "busy_workers_data": '[[10, 2]]', "period_production": 1}, # TODO в будущем добавь прядильщика 
		{"id": 75, "good_id": 29, "production_volume": 5, "material_costs_data": '[[24, 50], [17, 100], [13, 2]]', "busy_workers_data": '[[10, 2]]', "period_production": 1}, # TODO в будущем добавь прядильщика 
		{"id": 76, "good_id": 29, "production_volume": 10, "material_costs_data": '[[24, 100], [17, 200], [27, 1]]', "busy_workers_data": '[[10, 2]]', "period_production": 1}, # TODO в будущем добавь прядильщика 
		{"id": 77, "good_id": 30, "production_volume": 10, "material_costs_data": '[[12, 120]]', "busy_workers_data": '[[11, 1]]', "period_production": 1},
		{"id": 78, "good_id": 30, "production_volume": 20, "material_costs_data": '[[12, 120], [13, 2]]', "busy_workers_data": '[[11, 1]]', "period_production": 1},
		{"id": 79, "good_id": 30, "production_volume": 35, "material_costs_data": '[[12, 120], [27, 1]]', "busy_workers_data": '[[11, 1]]', "period_production": 1},
		{"id": 80, "good_id": 31, "production_volume": 4, "material_costs_data": '[[30, 24], [10, 80], [13, 2]]', "busy_workers_data": '[[11, 1]]', "period_production": 2},
		{"id": 81, "good_id": 31, "production_volume": 16, "material_costs_data": '[[30, 96], [10, 320], [27, 1]]', "busy_workers_data": '[[11, 2]]', "period_production": 2},
		{"id": 82, "good_id": 32, "production_volume": 2, "material_costs_data": '[[30, 4], [25, 80], [27, 2]]', "busy_workers_data": '[[11, 2]]', "period_production": 1},
		{"id": 83, "good_id": 34, "production_volume": 10, "material_costs_data": '[[18, 2]]', "busy_workers_data": '[[8, 1]]', "period_production": 1},
		{"id": 84, "good_id": 34, "production_volume": 40, "material_costs_data": '[[18, 4], [13, 2]]', "busy_workers_data": '[[8, 1]]', "period_production": 1}
	]
}



## Функция для получения определения таблицы
static func get_table_definition(table_name: String) -> Dictionary:
	return TABLE_DEFINITIONS.get(table_name, {})


## Функция для получения статичных данных таблицы
static func get_static_data(table_name: String) -> Array:
	return STATIC_DATA.get(table_name, [])
