extends Node2D
## Isolated, repeatable effects playground. Never enters or settles campaign progress.
const FONT := preload("res://resources/ui_font.tres")
@onready var player: RemixPlayer = $World/Steve
@onready var equipment: WeaponController = $World/Steve/Equipment
@onready var health: HealthComponent = $World/Steve/Health
var wallet: EmeraldWallet
var targets: Array[TrainingDummy] = []
var target_count := 3
var overlay: Node2D

func _ready() -> void:
    get_window().title = "Minecraft Remix | 剑光与落雷 · 特效试炼"
    var ui := CanvasLayer.new()
    ui.name = "UI"
    ui.layer = 10
    add_child(ui)
    overlay = Node2D.new()
    ui.add_child(overlay)
    overlay.draw.connect(_draw_overlay)
    wallet = EmeraldWallet.new()
    player.add_child(wallet)
    equipment.wallet = wallet
    equipment.configure_loadout(["netherite_sword", "trident"])
    for index in 3:
        var target := TrainingDummy.new()
        target.hit_points = 500
        target.position = [Vector2(246,288),Vector2(404,288),Vector2(542,220)][index]
        target.label = "木靶 %d" % (index + 1)
        target.ui_font = FONT
        $World.add_child(target)
        targets.append(target)
    reset_room()
    print("M4AH2_VFX_LAB_READY")

func reset_room() -> void:
    get_tree().paused = false
    for projectile in get_tree().get_nodes_in_group("projectiles"):
        if projectile.has_method("retire"): projectile.retire()
        else: projectile.queue_free()
    equipment.reset_equipment()
    health.reset_health()
    player.reset_at(Vector2(160,288))
    player.facing = 1
    wallet.reset_to_entry(200)
    for target in targets: target.reset_target()
    set_target_count(target_count)

func set_target_count(count: int) -> void:
    target_count = clampi(count,1,3)
    for index in targets.size():
        targets[index].visible = index < target_count
        targets[index].receiver.set_deferred("collision_layer",16 if index < target_count else 0)

func _process(_delta: float) -> void:
    player.position.x = clampf(player.position.x,20,620)
    overlay.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_R: reset_room()
            KEY_T: set_target_count(1 if target_count == 3 else 3)
            KEY_ESCAPE:
                equipment.suspend_input()
                get_tree().paused = not get_tree().paused
            KEY_Q:
                get_tree().paused = false
                get_tree().quit()

func _draw() -> void:
    draw_rect(Rect2(0,288,640,72),Color("3a433b"))
    draw_rect(Rect2(0,288,640,4),Color("a3b36b"))
    for x in range(0,640,32):
        draw_rect(Rect2(x,294,31,29),Color("586057"))
    draw_rect(Rect2(490,220,104,8),Color("9a8051"))
    draw_rect(Rect2(490,220,104,2),Color("d8b773"))

func _draw_overlay() -> void:
    overlay.draw_rect(Rect2(12,12,616,58),Color("102b31f5"))
    overlay.draw_string(FONT,Vector2(24,34),"剑光与落雷 / 特效试炼",0,-1,16,Color("f3e6ba"))
    overlay.draw_string(FONT,Vector2(24,56),"普通剑光 · 巨剑大招 · 天降雷霆   |   独立练习，不写入远征存档",0,-1,10,Color("b4ccbb"))
    if not is_instance_valid(equipment): return
    overlay.draw_rect(Rect2(12,316,616,36),Color("102b31f5"))
    overlay.draw_string(FONT,Vector2(22,331),"A/D 移动  空格 跳跃  J 攻击  K 切武器  L 大招  |  %s · 宝石 %d" % [equipment.equipped().label,wallet.available()],0,-1,10,Color("f3e6ba"))
    overlay.draw_string(FONT,Vector2(22,345),"R 重置补充   T 切换单靶/三靶   Esc 暂停   F11 全屏   Q 退出",0,-1,10,Color("b4ccbb"))
    if get_tree().paused:
        overlay.draw_string(FONT,Vector2(266,160),"已暂停",0,-1,20,Color("f3e6ba"))
