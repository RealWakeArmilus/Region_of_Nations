extends MyException

var handler = AppData.handler[0]


'''
# BASIC BUTTON #

open_link - открыть браузерную ссылку
exit_app - закрыть приложение
all_touch - клик для ПК и смартфона
'''
func open_link(append_lick_browser : String):
	if check_str(append_lick_browser):
		OS.shell_open(append_lick_browser)


func exit_app():
	get_tree().quit()


func all_touch(append_event):
	if append_event is InputEventScreenTouch or append_event.is_action_pressed('left_mouse'):
		return true
	else:
		return false


'''
# PAGE CONTROL #

open_page() - открыть страницу
close_page() - закрыть страницу
'''
func close_page(append_page: Array, append_main : String = ''):
	get_node('/root/' + append_main).get_node(append_page[0]).queue_free() # format 'NamePage'

func open_page(append_page: Array, append_main : String = ''):
	get_node('/root/' + append_main).add_child(load(append_page[1]).instantiate()) # format "res://derictory/Name_file.tscn"



## 1. Закрывает старницу "intro". 
## 2. Открывает страницу "handler".
func intro_close():
	close_page(AppData.intro)
	open_page(AppData.handler)


## 1. Закрывает страницу "main_menu". 
## 2. Открывает страницу "campaign".
func from_main_menu_in_campaign():
	close_page(AppData.main_menu, handler)
	open_page(AppData.campaign, handler)

## 1. Закрывает страницу "campaign". 
## 2. Открывает страницу "main_menu".
func from_campaign_in_main_menu():
	close_page(AppData.campaign, handler)
	open_page(AppData.main_menu, handler)


## 1. Закрывает страницу "main_menu". 
## 2. Открывает страницу "loading".
func from_main_menu_in_loading():
	close_page(AppData.main_menu, handler)
	open_page(AppData.loading, handler)


'''
# SOLO GAMES #

open_page_solo_games()
	1. Закрывает страницу MainMenu
	2. Открывает страницу SoloGames
'''
func open_page_solo_games():
	close_page(AppData.main_menu, handler)
	open_page(AppData.solo_games, handler)
func close_page_solo_games():
	close_page(AppData.solo_games, handler)
	open_page(AppData.main_menu, handler)


'''
# MAIN SETTINGS #

open_page_main_settings()
	1. Закрывает страницу MainMenu
	2. Открывает страницу MainSettings
'''
func open_page_main_settings():
	close_page(AppData.main_menu, handler)
	open_page(AppData.main_settings, handler)
func close_page_main_settings():
	close_page(AppData.main_settings, handler)
	open_page(AppData.main_menu, handler)


'''
# CREATE WORLD #

open_page_create_world()
	1. Закрывает страницу SoloGames
	2. Открывает страницу CreateWorld
'''
func open_page_create_world():
	close_page(AppData.solo_games, handler)
	open_page(AppData.create_world, handler)


'''
# LOADING #

open_page_loading()
	1. Открывает страницу Loading
'''
func open_page_loading():
	close_page(AppData.create_world, handler)
	open_page(AppData.loading, handler)


'''
# WIDGET CONTROL #

open_widget() - открыть страницу
close_widget() - закрыть страницу
'''
func close_widget(append_widget: Array, append_main : String = ''):
	get_node('/root/' + append_main).get_node(append_widget[0]).queue_free() # format 'NamePage'
func open_widget(append_widget: Array, append_main : String = ''):
	get_node('/root/' + append_main).add_child(load(append_widget[1]).instantiate()) # format "res://derictory/Name_file.tscn"


#
#func open_page(main_page: String, open_page: String):
	#if check_str(main_page) and check_mix_with(open_page, AppPage.scene, '.tscn'):
		#get_node('/root/' + main_page).add_child(load(open_page).instantiate()) # format "res://Scene/derictory/Name_file.tscn"
#func close_open_page(main_page: String, close_page: String, open_page: String):
	#if check_str(main_page) and check_str(close_page) and check_mix_with(open_page, AppPage.scene, '.tscn'):
		#get_node('/root/' + main_page).get_node(close_page).queue_free() # format 'NamePage'
		#get_node('/root/' + main_page).add_child(load(open_page).instantiate()) # format "res://Scene/derictory/Name_file.tscn"
#
#
#func close_widget(main_page: String, close_name_widget: String):
	#if check_str(main_page) and check_str(close_name_widget):
		#get_node('/root/' + main_page).get_node(close_name_widget).queue_free() # format 'NamePage'
#func open_widget(main_page: String, open_name_widget: String):
	#if check_str(main_page) and check_mix_with(open_name_widget, AppPage.widgets, '.tscn'):
		#get_node('/root/' + main_page).add_child(load(open_name_widget).instantiate()) # format "res://Widgets/derictory/Name_file.tscn"
#func close_open_widgets(main_page: String, close_name_widget: String, open_name_widget: String):
	#if check_str(main_page) and check_str(close_name_widget) and check_mix_with(open_name_widget, AppPage.widgets, '.tscn'):
		#get_node('/root/' + main_page).get_node(close_name_widget).queue_free() # format 'NamePage'
		#get_node('/root/' + main_page).add_child(load(open_name_widget).instantiate()) # format "res://Widgets/derictory/Name_file.tscn"
#
#
#func open_demo_view_build(open_demo_view_build: String):
	#if check_mix_with(open_demo_view_build, AppPage.demo_build, '.tscn'):
		#get_node('/root/Handler/CustomGame/Player/UI/Page/DemoViewBuilds/MC/Builds').add_child(load(open_demo_view_build).instantiate()) # format "res://Demo_view_build/Type/Name_build.tscn"
#
#
#func close_object(close_name_object : String):
	#if check_str(close_name_object):
		#get_node('/root/Handler/CustomGame/Procedural2Version/TileMap').get_node(close_name_object).queue_free() # format 'NamePage'
