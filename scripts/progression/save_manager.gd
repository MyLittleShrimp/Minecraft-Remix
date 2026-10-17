extends Node
## One committed checkpoint plus one verified backup. Tests opt in with their own path.
signal status_changed
var save_path := "user://campaign.json"
var enabled := false
var single_chapter := false
var selected_chapter := "forest_ruins"
var menu_return_chapters := false
var pending_resume: Dictionary = {}
var last_committed: Dictionary = {}
var notice := ""
var last_error: Error = OK

func _ready() -> void:
    var override := OS.get_environment("REMIX_SAVE_PATH")
    if not override.is_empty(): save_path=override

func any_file() -> bool:
    return FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak") or FileAccess.file_exists(save_path+".tmp")

func read_candidate(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {}
    var file := FileAccess.open(path,FileAccess.READ)
    if file==null: return {}
    if file.get_length()>1048576: return {}
    var json := JSON.new()
    var result := json.parse(file.get_as_text())
    file.close()
    if result!=OK or not RunSaveCodec.validate(json.data).is_empty(): return {}
    return RunSaveCodec.migrate(json.data)

func inspect_save() -> Dictionary:
    notice=""
    for suffix in ["",".bak",".tmp"]:
        var data := read_candidate(save_path+suffix)
        if not data.is_empty():
            if suffix==".bak": notice="主存档不可用，已找到上一份备份。"
            elif suffix==".tmp": notice="已找到中断前写好的存档，可以恢复。"
            return data
    if any_file(): notice="存档损坏或版本不兼容；原文件保留，可开始新远征。"
    return {}

func prepare_new() -> void:
    single_chapter=false
    selected_chapter="forest_ruins"
    FinaleCampaign.transfer.clear()
    enabled=true
    pending_resume.clear()
    last_committed.clear()
    notice=""
    last_error=OK
    get_node("/root/RunProgress").new_campaign()

func prepare_continue() -> bool:
    single_chapter=false
    FinaleCampaign.transfer.clear()
    var data := inspect_save()
    if data.is_empty(): return false
    enabled=true
    last_error=OK
    pending_resume=data.duplicate(true)
    last_committed=data.duplicate(true)
    get_node("/root/RunProgress").restore_entry(int(data.entry_balance),data.entry_story_items)
    return true

func prepare_chapter(id: String, standalone: bool) -> bool:
    if not CampaignCatalog.LEVELS.has(id): return false
    prepare_new()
    single_chapter=standalone
    selected_chapter=id
    enabled=not standalone
    # Chapter starts have a fresh resource budget, plus only the story keys
    # required by the chosen chapter. No previous victories are fabricated.
    var inventory: Dictionary={"ender_pearl":3 if id in ["fortress_core","the_end"] else 0,"blaze_powder":3 if id=="the_end" else 0}
    get_node("/root/RunProgress").restore_entry(0,inventory)
    return true

func write_record(data: Dictionary) -> Error:
    # Validate JSON-roundtripped values, including StringName -> String map keys.
    var encoded := JSON.stringify(data,"  ")
    var invalid := RunSaveCodec.validate(JSON.parse_string(encoded))
    if not invalid.is_empty():
        print("SAVE_REJECT reason=",invalid)
        return ERR_INVALID_DATA
    var absolute := ProjectSettings.globalize_path(save_path)
    var error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
    if error!=OK: return error
    error=_write_text(save_path+".tmp",encoded)
    if error!=OK: return error
    if read_candidate(save_path+".tmp").is_empty(): return ERR_FILE_CORRUPT
    # Never replace a good backup with a corrupt primary. Backup publication is
    # itself staged, so a failed write keeps at least the previous good record.
    var previous := read_candidate(save_path)
    if not previous.is_empty():
        error=_write_text(save_path+".bak.tmp",JSON.stringify(previous,"  "))
        if error!=OK: return error
        if read_candidate(save_path+".bak.tmp").is_empty(): return ERR_FILE_CORRUPT
        error=DirAccess.rename_absolute(absolute+".bak.tmp",absolute+".bak")
        if error!=OK: return error
    return DirAccess.rename_absolute(absolute+".tmp",absolute)

func _write_text(path: String, text: String) -> Error:
    var file := FileAccess.open(path,FileAccess.WRITE)
    if file==null: return FileAccess.get_open_error()
    file.store_string(text)
    file.flush()
    var error := file.get_error()
    file.close()
    return error

func save_level(level: Node, snapshot: CheckpointSnapshot, finished: bool = false) -> bool:
    if not enabled: return true
    if not CampaignCatalog.LEVELS.has(str(level.campaign_level_id)): return false
    var data := RunSaveCodec.pack(level,snapshot,finished)
    last_error=write_record(data)
    if last_error==OK:
        last_committed=JSON.parse_string(JSON.stringify(data))
        notice="通关记录已保存" if finished else "进度已保存 · "+level.checkpoint_specs()[snapshot.checkpoint_index].label
    else: notice="保存失败（%d）· 上次存档仍保留，请暂停后重试保存。" % last_error
    print("SAVE_WRITE ok=%s checkpoint=%s completed=%s" % [last_error==OK,snapshot.checkpoint_id,finished])
    status_changed.emit()
    return last_error==OK

func return_to_menu() -> void:
    menu_return_chapters=single_chapter
    single_chapter=false
    FinaleCampaign.transfer.clear()
    enabled=false
    pending_resume.clear()
    get_tree().paused=false
    var settings := get_node("/root/ControlSettings")
    settings.menu_open=false
    settings.arm_release_gate()
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
