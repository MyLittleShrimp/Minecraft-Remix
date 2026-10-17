extends SceneTree
## Small, portable release check. Always isolate player files before running.
var checks := 0
var failures := 0
var saves: Node

func _initialize() -> void:
    run.call_deferred()

func ticks(count: int = 4) -> void:
    for i in count:
        await physics_frame
        await process_frame

func check(ok: bool, label: String) -> void:
    checks+=1
    failures+=int(not ok)
    print(("PASS " if ok else "FAIL ")+label)

func capture(name: String) -> void:
    var folder:=OS.get_environment("REMIX_CAPTURE_DIR")
    if folder.is_empty() or DisplayServer.get_name()=="headless": return
    DirAccess.make_dir_recursive_absolute(folder)
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(folder.path_join(name+".png"))==OK,"capture "+name)

func run() -> void:
    assert(not OS.get_environment("REMIX_SAVE_PATH").is_empty())
    assert(not OS.get_environment("REMIX_CONTROLS_PATH").is_empty())
    root.size=Vector2i(1600,900)
    saves=root.get_node("SaveManager")
    saves.enabled=false
    var settings: Node=root.get_node("ControlSettings")
    settings.guide_enabled=false
    settings.mode="keyboard"
    settings.rebuild()
    var music: Node=root.get_node("MusicDirector")
    check(music.TRACKS.size()==16,"sixteen soundtrack entries")
    for id in music.TRACKS:
        var stream: AudioStreamMP3=music.track_stream(id)
        check(stream!=null and stream.get_length()>20 and stream.loop,"music asset "+id)
    change_scene_to_file("res://scenes/main_menu.tscn")
    await ticks(65)
    check(current_scene is Control,"main menu loads")
    await capture("01-main-menu")
    for id in CampaignCatalog.LEVELS:
        current_scene.start_chapter(id,true)
        await ticks(65)
        var level: Node=current_scene
        check(str(level.campaign_level_id)==id and level.health.current>0,"chapter loads "+id)
        check(is_instance_valid(level.music_button),"music control "+id)
        if id=="forest_ruins": await capture("02-forest")
        if id=="abandoned_mine": await capture("03-mine")
        if id=="tidal_ruins":
            await capture("04-tidal-ruins")
            level.player.reset_at(Vector2(level.armory_positions()[0],288))
            level.loadout_panel.open_panel()
            await ticks(6)
            await capture("05-weapons")
            level.loadout_panel.close_panel()
        if id=="fortress_core": await capture("06-fortress")
        saves.return_to_menu()
        await ticks(8)
    for segment in ["portal","dragon"]:
        var scene:=load(CampaignCatalog.scene_path("the_end",segment)) as PackedScene
        check(scene!=null and scene.can_instantiate(),"finale resource "+segment)
    await ticks(60)
    print("RELEASE_SMOKE checks=%d failures=%d" % [checks,failures])
    quit(int(failures>0))
