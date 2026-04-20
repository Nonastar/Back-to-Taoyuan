extends Node

## I18n - 国际化/本地化支持
## 提供 tr(key) 函数返回当前语言对应的翻译字符串
## 翻译表位于 assets/data/translations/strings.csv
## 当前默认语言: zh (中文)

const DEFAULT_LOCALE := "zh"
const SUPPORTED_LOCALES := ["zh", "en"]

const TRANSLATIONS_PATH := "res://assets/data/translations/strings.csv"

var _strings: Dictionary = {}  # {key: {zh: "", en: ""}}
var _current_locale: String = DEFAULT_LOCALE

func _ready() -> void:
	_load_translations()

## 获取当前语言
func get_locale() -> String:
	return _current_locale

## 设置语言
func set_locale(locale: String) -> void:
	if locale in SUPPORTED_LOCALES:
		_current_locale = locale
		print("[I18n] Locale set to: ", _current_locale)
	else:
		push_warning("[I18n] Unsupported locale: " + locale)

## 获取翻译字符串
## 用法: I18n.translate("weather.sunny")
func translate(key: String) -> String:
	if not _strings.has(key):
		push_warning("[I18n] Missing translation key: " + key)
		return key  # fallback to key itself

	var translation = _strings[key].get(_current_locale, "")
	if translation == "":
		# fallback to Chinese if current locale has no translation
		translation = _strings[key].get(DEFAULT_LOCALE, key)
	return translation

## 格式化翻译字符串 (支持 %s/%d 占位符)
## 用法: I18n.trf("animal.cured", ["小鸡", "10"])
func trf(key: String, args: Array = []) -> String:
	var template := translate(key)
	if template == key or args.is_empty():
		return template
	return template % args

## 加载CSV翻译表
func _load_translations() -> void:
	if not FileAccess.file_exists(TRANSLATIONS_PATH):
		push_warning("[I18n] Translation file not found: " + TRANSLATIONS_PATH)
		return

	var file = FileAccess.open(TRANSLATIONS_PATH, FileAccess.READ)
	if file == null:
		push_error("[I18n] Failed to open translation file: " + TRANSLATIONS_PATH)
		return

	var csv_content = file.get_as_text()
	file.close()

	var lines = csv_content.split("\n", false)
	for line in lines:
		# 跳过空行、注释行、标题行
		var trimmed = line.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("#"):
			continue
		if trimmed.begins_with("key,") or trimmed.begins_with("key\t"):
			continue  # 跳过标题行

		# CSV格式: key,zh,en,context
		var parts = trimmed.split(",", false)
		if parts.size() < 2:
			continue

		var key = parts[0].strip_edges()
		var zh_text = parts[1].strip_edges() if parts.size() > 1 else ""
		var en_text = parts[2].strip_edges() if parts.size() > 2 else ""

		_strings[key] = {
			"zh": zh_text,
			"en": en_text
		}

	print("[I18n] Loaded %d translation strings" % _strings.size())

## 获取所有可用key (用于调试)
func get_all_keys() -> Array:
	return _strings.keys()

## 检查key是否存在
func has_key(key: String) -> bool:
	return _strings.has(key)
