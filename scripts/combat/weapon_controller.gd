class_name WeaponController
extends Node2D

signal shot_fired(damage: int, direction: Vector2)
signal swung
signal ultimate_used(label: String)
signal ultimate_denied(reason: String)
@export var weapons: Array[WeaponData] = []
@export var health: HealthComponent
@onready var actor: RemixPlayer = get_parent()
@onready var hitbox: MeleeHitbox = $Hitbox
var slot: int = 0
var cooldowns: Dictionary = {}
var charging: bool = false
var charge: float = 0.0
var sword_time: float = -1.0
var sword_event: DamageEvent
var sword_weapon: WeaponData
var sword_facing: int = 1
var release_required: bool = false
var damage_scale: float = 1.0
var attack_speed: float = 1.0
var shot_pose_left: float = 0.0
var ultimate_left: float = 0.0
var ultimate_recovery_left: float = 0.0
var ultimate_weapon: WeaponData
var wallet: EmeraldWallet
var crossbow_ammo: int = 0
var trident_flight: ReturningTrident
var lightning_cast: TridentLightning

func loadout_ids() -> Array[String]:
    var result: Array[String] = []
    for weapon in weapons: result.append(str(weapon.id))
    return result

func configure_loadout(ids: Array) -> void:
    # Caller validates unlocks. Preserve ammo and per-weapon cooldowns when swapping.
    var active_id: StringName = equipped().id
    cancel_attack()
    var selected: Array[WeaponData] = []
    for id in ids:
        var data: WeaponData = load("res://resources/weapons/%s.tres" % id)
        selected.append(data)
        if not cooldowns.has(data.id): cooldowns[data.id]=0.0
    weapons=selected
    slot=maxi(0,ids.find(str(active_id)))
    release_required=true

func _ready() -> void:
    process_physics_priority = -10
    for weapon in weapons:
        cooldowns[weapon.id] = 0.0
    health.damaged.connect(_on_damaged)
    health.died.connect(_on_died)

func equipped() -> WeaponData:
    return weapons[slot]

func _physics_process(delta: float) -> void:
    var attack_delta:=delta*(1.0 if ultimate_left>0 or ultimate_recovery_left>0 else attack_speed)
    shot_pose_left = maxf(0,shot_pose_left-delta)
    for id in cooldowns:
        cooldowns[id] = maxf(0.0, cooldowns[id] - attack_delta)
    actor.movement_scale = 1.0
    if health.current <= 0 or actor.controls_locked:
        queue_redraw()
        return
    var controls := actor.input_provider
    ultimate_left = maxf(0, ultimate_left-delta)
    ultimate_recovery_left = maxf(0, ultimate_recovery_left-delta)
    if actor.carrying_tool:
        actor.movement_scale=0.8
        queue_redraw()
        return
    if controls.ultimate_pressed() and try_ultimate():
        queue_redraw()
        return
    if release_required:
        if not controls.attack_held():
            release_required = false
        queue_redraw()
        return
    if controls.switch_pressed():
        cancel_attack()
        slot = (slot + 1) % weapons.size()
        release_required = controls.attack_held()
        queue_redraw()
        return
    var weapon := equipped()
    if weapon.kind==WeaponData.Kind.TRIDENT:
        _update_trident(weapon,controls,attack_delta)
    elif weapon.is_melee():
        if sword_time >= 0.0:
            sword_time += attack_delta
            if sword_time >= sword_weapon.windup + sword_weapon.active_seconds + sword_weapon.recovery:
                sword_time = -1.0
        if (controls.attack_pressed() or controls.attack_held()) and cooldowns[weapon.id] <= 0.0 and actor.hitstun_left <= 0.0:
            sword_time = 0.0
            sword_weapon = weapon.duplicate() if giant_sword_active() else weapon
            sword_facing = actor.facing
            var scale := damage_scale
            if giant_sword_active():
                sword_weapon.reach *= weapon.ultimate.reach_multiplier
                sword_weapon.hit_height *= 1.35
                # Mushroom and critical multipliers take the stronger value;
                # they do not multiply into an accidental boss one-shot.
                scale = maxf(scale, weapon.ultimate.damage_multiplier)
            sword_event = DamageEvent.create(actor, health.faction, ceili(weapon.damage * scale), Vector2(sword_facing * 140, -110))
            sword_event.set_meta("critical",giant_sword_active())
            _tag_melee(sword_event, sword_weapon)
            cooldowns[weapon.id] = weapon.windup + weapon.active_seconds + weapon.recovery
            hitbox.begin()
            swung.emit()
        if sword_time >= 0:
            actor.movement_scale = sword_weapon.melee_move_scale
    elif weapon.kind==WeaponData.Kind.CROSSBOW:
        if controls.attack_pressed() and cooldowns[weapon.id]<=0 and actor.hitstun_left<=0:
            if crossbow_ammo:
                _fire_bolt(weapon)
            else:
                charging=true
                charge=0
        if charging:
            if not controls.attack_held():
                cancel_attack()
            else:
                charge=minf(weapon.charge_seconds,charge+attack_delta)
                actor.movement_scale=weapon.charge_move_scale
                if charge>=weapon.charge_seconds:
                    crossbow_ammo=2
                    cancel_attack()
                    release_required=true
    else:
        if controls.attack_pressed() and cooldowns[weapon.id] <= 0.0 and actor.hitstun_left <= 0.0:
            charging = true
            charge = 0.0
        if charging:
            charge = minf(weapon.charge_seconds, charge + attack_delta)
            actor.movement_scale = weapon.charge_move_scale
            if controls.attack_released() or not controls.attack_held():
                _shoot(weapon)
    queue_redraw()

func giant_sword_active() -> bool:
    return ultimate_left > 0 and ultimate_weapon == equipped() and ultimate_weapon.ultimate.effect == UltimateData.Effect.GIANT_SWORD

func _tag_melee(event: DamageEvent, data: WeaponData) -> void:
    event.set_meta("stagger", data.stagger_seconds)
    event.set_meta("recovery_bonus", data.recovery_bonus)
    event.set_meta("wood_power", data.wood_power)

func try_ultimate() -> bool:
    if not is_instance_valid(wallet): return false
    if get_tree().paused or actor.dead or health.current <= 0 or actor.controls_locked or actor.carrying_tool or actor.hitstun_left > 0:
        return false
    var weapon := equipped()
    if weapon.kind==WeaponData.Kind.TRIDENT and trident_out():
        ultimate_denied.emit("三叉戟正在回收，接住后再施放")
        return false
    var ability := weapon.ultimate
    if ability == null or ability.effect == UltimateData.Effect.NONE: return false
    if ability.effect==UltimateData.Effect.TRIPLE_LIGHTNING and TridentLightning.candidates(actor,health.faction,ability.target_range).is_empty():
        ultimate_denied.emit("当前画面没有可锁定的敌人")
        return false
    if ultimate_left > 0 or ultimate_recovery_left > 0:
        ultimate_denied.emit("大招正在生效或收招中")
        return false
    if not wallet.try_spend(ability.emerald_cost):
        ultimate_denied.emit("还差 %d 颗绿宝石" % maxi(0,ability.emerald_cost-wallet.available()))
        return false
    cancel_attack()
    ultimate_weapon = weapon
    ultimate_recovery_left = ability.recovery
    match ability.effect:
        UltimateData.Effect.TRIPLE_LIGHTNING:
            var blast:=TridentLightning.new()
            lightning_cast=blast
            blast.wielder=actor
            blast.position=actor.global_position+Vector2(0,-24)
            blast.reach=ability.target_range
            blast.target_limit=ability.lightning_targets
            blast.splash_radius=ability.splash_radius
            blast.splash_damage=ability.splash_damage
            blast.windup=ability.melee_windup
            blast.event=DamageEvent.create(actor,health.faction,ability.arrow_damage,Vector2(0,-90))
            blast.event.set_meta("stagger",0.35)
            blast.event.set_meta("trident_lightning",true)
            actor.get_parent().add_child(blast)
            shot_pose_left=ability.melee_windup+0.2
            cooldowns[weapon.id]=maxf(cooldowns[weapon.id],ability.recovery)
            release_required=actor.input_provider.attack_held()
            shot_fired.emit(ability.arrow_damage,Vector2.DOWN)
        UltimateData.Effect.HEAVY_CLEAVE:
            sword_weapon = weapon.duplicate()
            sword_weapon.windup = ability.melee_windup
            sword_weapon.reach = ability.melee_reach
            sword_weapon.hit_height = 64
            sword_weapon.recovery = ability.recovery - ability.melee_windup - weapon.active_seconds
            sword_weapon.stagger_seconds = ability.melee_stagger
            sword_weapon.recovery_bonus = 0
            sword_time = 0
            sword_facing = actor.facing
            sword_event = DamageEvent.create(actor, health.faction, ability.melee_damage, Vector2(sword_facing * 150, -110))
            sword_event.set_meta("heavy_cleave", true)
            _tag_melee(sword_event, sword_weapon)
            cooldowns[weapon.id] = ability.recovery
            release_required = false
            actor.movement_scale = sword_weapon.melee_move_scale
            hitbox.begin()
            swung.emit()
        UltimateData.Effect.GIANT_SWORD:
            ultimate_left = ability.duration
        UltimateData.Effect.MULTISHOT:
            var direction := aim_direction()
            var damage := ceili(ability.arrow_damage * damage_scale)
            for i in ability.arrow_count:
                var angle := deg_to_rad((i-(ability.arrow_count-1)*0.5)*ability.spread_degrees)
                var arrow := ArrowProjectile.new()
                arrow.position = actor.global_position+Vector2(0,-24)
                arrow.velocity = direction.rotated(angle)*weapon.charged_arrow_speed
                arrow.empowered = true
                arrow.event = DamageEvent.create(actor,health.faction,damage,Vector2(signf(direction.x)*130,-80))
                actor.get_parent().add_child(arrow)
            shot_pose_left = 0.3
            cooldowns[weapon.id] = maxf(cooldowns[weapon.id],ability.recovery)
            release_required = actor.input_provider.attack_held()
            # One volley is one food payment and one sound, not five charges.
            shot_fired.emit(damage,direction)
        UltimateData.Effect.PIERCING_BOLT:
            var direction:=aim_direction()
            var arrow:=ArrowProjectile.new()
            var damage:=ceili(ability.arrow_damage*damage_scale)
            arrow.position=actor.global_position+Vector2(0,-24)
            arrow.velocity=direction*weapon.arrow_speed
            arrow.empowered=true
            arrow.bolt=true
            arrow.targets_remaining=ability.pierce_targets
            arrow.event=DamageEvent.create(actor,health.faction,damage,Vector2(signf(direction.x)*180,-80))
            actor.get_parent().add_child(arrow)
            shot_pose_left=0.3
            cooldowns[weapon.id]=maxf(cooldowns[weapon.id],ability.recovery)
            release_required=actor.input_provider.attack_held()
            shot_fired.emit(damage,direction)
    ultimate_used.emit(ability.label)
    queue_redraw()
    return true

func clear_ultimate() -> void:
    ultimate_left = 0
    ultimate_recovery_left = 0
    ultimate_weapon = null

func _fire_bolt(weapon: WeaponData) -> void:
    var direction:=aim_direction()
    var damage:=ceili(weapon.damage*damage_scale)
    var arrow:=ArrowProjectile.new()
    arrow.position=actor.global_position+Vector2(0,-24)
    arrow.velocity=direction*weapon.arrow_speed
    arrow.bolt=true
    arrow.event=DamageEvent.create(actor,health.faction,damage,Vector2(signf(direction.x)*160,-80))
    actor.get_parent().add_child(arrow)
    crossbow_ammo=maxi(0,crossbow_ammo-1)
    cooldowns[weapon.id]=weapon.quick_cooldown
    shot_pose_left=0.2
    release_required=true
    shot_fired.emit(damage,direction)

func _shoot(weapon: WeaponData) -> void:
    var full := charge >= weapon.charge_seconds - 0.001
    var direction := aim_direction()
    var damage := ceili((weapon.charged_damage if full else weapon.damage) * damage_scale)
    var arrow := ArrowProjectile.new()
    arrow.position = actor.global_position + Vector2(0, -24)
    arrow.velocity = direction * (weapon.charged_arrow_speed if full else weapon.arrow_speed)
    arrow.event = DamageEvent.create(actor, health.faction, damage, Vector2(signf(direction.x) * (180 if full else 90), -80))
    actor.get_parent().add_child(arrow)
    cooldowns[weapon.id] = weapon.charged_recovery if full else weapon.quick_cooldown
    charging = false
    charge = 0.0
    actor.movement_scale = 1.0
    shot_pose_left = 0.16
    shot_fired.emit(damage, direction)

func aim_direction() -> Vector2:
    var vertical := -1.0 if actor.input_provider.up_held() else (1.0 if actor.input_provider.down_held() and not actor.is_on_floor() else 0.0)
    return Vector2(actor.facing, vertical).normalized()

func cancel_attack() -> void:
    if is_instance_valid(lightning_cast) and not lightning_cast.struck:
        lightning_cast.retire()
    charging = false
    charge = 0.0
    sword_time = -1.0
    actor.movement_scale = 1.0

func suspend_input() -> void:
    cancel_attack()
    release_required = true

func reset_equipment() -> void:
    if trident_out(): trident_flight.retire()
    cancel_attack()
    clear_ultimate()
    slot = 0
    crossbow_ammo=0
    for id in cooldowns:
        cooldowns[id] = 0.0
    release_required = true

func _on_damaged(event: DamageEvent) -> void:
    if event.get_meta("starvation",false) or event.get_meta("poison_tick",false) or event.get_meta("wither_tick",false): return
    suspend_input()
    actor.receive_knockback(event.impulse)

func _on_died() -> void:
    if trident_out(): trident_flight.retire()
    if is_instance_valid(lightning_cast): lightning_cast.retire()
    clear_ultimate()
    actor.dead = true
    actor.clear_jump_memory()

func _draw() -> void:
    if not is_instance_valid(actor) or health.current<=0 or actor.carrying_tool: return
    if equipped().kind==WeaponData.Kind.SWORD:
        var tilt := -0.1 if sword_time<0 else lerpf(-0.8,1.1,clampf(sword_time/0.17,0,1))
        var direction := sword_facing if sword_time>=0 else actor.facing
        var enlarged: bool = giant_sword_active() or (sword_time>=0 and sword_event!=null and sword_event.get_meta("critical",false))
        var factor := equipped().ultimate.reach_multiplier if enlarged else 1.0
        if enlarged:
            draw_arc(Vector2(0,-20),29,0,TAU,12,Color(0.38,1.0,0.75,0.45),2)
            for i in 4:
                var phase := (6-ultimate_left)*2+i*PI/2
                draw_rect(Rect2(Vector2(cos(phase)*25,-23+sin(phase)*25),Vector2(3,3)),Color("b8ffe4"))
        draw_set_transform(Vector2(direction*9,-23),tilt*direction,Vector2(direction,1)*factor)
        RemixArt.icon(self,4,Rect2(-3,-27,33,33))
        if sword_time>=equipped().windup and sword_time<equipped().windup+equipped().active_seconds:
            draw_arc(Vector2(3,0),32,-0.8,0.7,7,Color("b8ffe4") if enlarged else Color(0.84,0.94,0.73,0.6),2)
    elif equipped().kind==WeaponData.Kind.TRIDENT:
        _draw_trident()
    elif equipped().kind == WeaponData.Kind.AXE:
        _draw_axe()
    elif equipped().kind==WeaponData.Kind.CROSSBOW:
        var aim:=aim_direction()
        var recoil:=3.0 if shot_pose_left>0 else 0.0
        draw_set_transform(Vector2(0,-24)+aim*(10-recoil),aim.angle(),Vector2(1,actor.facing))
        WeaponArt.crossbow(self,crossbow_ammo>0,charge/equipped().charge_seconds if charging else 0.0)
        draw_rect(Rect2(-9,3,5,4),Color("d6a070"))
        if charging: draw_rect(Rect2(-3-charge/equipped().charge_seconds*9,0,4,4),Color("d6a070"))
        draw_set_transform(Vector2.ZERO)

    else:
        var aim := aim_direction()
        # Bow is constructed around its grip, independent of diagonal inventory art.
        # Local +X always points toward the target; the string/nock stay behind it.
        draw_set_transform(Vector2(-actor.facing*4,-24)+aim*14,aim.angle(),Vector2(1,actor.facing))
        var ratio := clampf(charge/equipped().charge_seconds,0,1) if charging else 0.0
        var nock := Vector2(-3-ratio*11,0)
        var limb := PackedVector2Array([Vector2(-2,-16),Vector2(3,-13),Vector2(7,-7),Vector2(8,0),Vector2(7,7),Vector2(3,13),Vector2(-2,16)])
        draw_polyline(limb,Color("30221b"),5)
        draw_polyline(limb,Color("a36f36"),3)
        draw_polyline(PackedVector2Array([Vector2(-2,-15),Vector2(3,-12),Vector2(6,-7)]),Color("ddbc72"),1)
        draw_polyline(PackedVector2Array([Vector2(-2,-16),nock,Vector2(-2,16)]),Color("e8dbc0"),1)
        draw_rect(Rect2(6,-3,4,6),Color("563725"))
        # Front hand grips the stave, rear hand follows the pulled nock.
        draw_rect(Rect2(5,-2,5,4),Color("d6a070"))
        if charging:
            var color := Color("f6df8e") if ratio>=0.99 else Color("dfcda3")
            draw_line(nock,Vector2(26,0),color,1)
            draw_colored_polygon(PackedVector2Array([Vector2(29,0),Vector2(24,-2),Vector2(24,2)]),Color("d9e4dc"))
            draw_rect(Rect2(nock-Vector2(2,2),Vector2(4,4)),Color("d6a070"))
        draw_set_transform(Vector2.ZERO)

func trident_out() -> bool:
    return is_instance_valid(trident_flight) and not trident_flight.spent

func _update_trident(weapon: WeaponData,controls: Node,delta: float) -> void:
    if sword_time>=0:
        sword_time+=delta
        actor.movement_scale=weapon.melee_move_scale
        if sword_time>=weapon.windup+weapon.active_seconds+weapon.recovery: sword_time=-1
    if trident_out(): return
    if controls.attack_pressed() and cooldowns[weapon.id]<=0 and actor.hitstun_left<=0:
        charging=true
        charge=0
    if not charging: return
    charge=minf(weapon.charge_seconds,charge+delta)
    actor.movement_scale=weapon.charge_move_scale
    if not controls.attack_released() and controls.attack_held(): return
    var throwing:=charge>=weapon.charge_seconds-0.001
    charging=false
    charge=0
    if throwing:
        var projectile:=ReturningTrident.new()
        trident_flight=projectile
        projectile.wielder=actor
        projectile.position=actor.global_position+Vector2(0,-24)
        projectile.velocity=aim_direction()*weapon.charged_arrow_speed
        projectile.max_distance=weapon.throw_distance
        projectile.return_speed=weapon.return_speed
        projectile.event=DamageEvent.create(actor,health.faction,ceili(weapon.charged_damage*damage_scale),Vector2(actor.facing*150,-90))
        projectile.event.set_meta("trident_throw",true)
        actor.get_parent().add_child(projectile)
        cooldowns[weapon.id]=weapon.charged_recovery
        shot_pose_left=0.2
        shot_fired.emit(projectile.event.amount,aim_direction())
    else:
        sword_time=0
        sword_weapon=weapon
        sword_facing=actor.facing
        sword_event=DamageEvent.create(actor,health.faction,ceili(weapon.damage*damage_scale),Vector2(actor.facing*105,-60))
        _tag_melee(sword_event,weapon)
        cooldowns[weapon.id]=weapon.windup+weapon.active_seconds+weapon.recovery
        hitbox.begin()
        swung.emit()

func _draw_trident() -> void:
    if trident_out(): return
    var direction:=sword_facing if sword_time>=0 else actor.facing
    var extension:=0.0
    if sword_time>=0:
        if sword_time<sword_weapon.windup: extension=-8*sword_time/sword_weapon.windup
        elif sword_time<sword_weapon.windup+sword_weapon.active_seconds: extension=24
        else: extension=24*(1-clampf((sword_time-sword_weapon.windup-sword_weapon.active_seconds)/sword_weapon.recovery,0,1))
    elif charging: extension=-9*charge/equipped().charge_seconds
    var aim:=Vector2(direction,0) if sword_time>=0 else aim_direction()
    draw_set_transform(Vector2(direction*8,-24)+aim*extension,aim.angle(),Vector2(1,direction))
    var glow:=charging and charge>=equipped().charge_seconds-0.001
    WeaponArt.trident(self,Color("c6fff5") if glow or (is_instance_valid(lightning_cast) and not lightning_cast.spent) else Color.WHITE)
    if sword_time>=0 and sword_time>=sword_weapon.windup and sword_time<sword_weapon.windup+sword_weapon.active_seconds:
        # A short wake shows the remaining thrust reach; the shaft stays in hand.
        draw_line(Vector2(37,0),Vector2(sword_weapon.reach-8-extension,0),Color(0.65,1,0.95,0.65),2)
    draw_set_transform(Vector2(direction*8,-24)+aim*clampf(extension,-9,6),aim.angle(),Vector2(1,direction))
    draw_rect(Rect2(-3,-1,6,5),Color("d6a070"))
    draw_set_transform(Vector2.ZERO)

func _draw_axe() -> void:
    var data := sword_weapon if sword_time >= 0 else equipped()
    var direction := sword_facing if sword_time >= 0 else actor.facing
    var heavy: bool = sword_time >= 0 and sword_event.get_meta("heavy_cleave", false)
    var angle := 0.25
    if sword_time >= 0:
        if sword_time < data.windup:
            angle = lerpf(0.25, -1.0, sword_time / data.windup)
        elif sword_time < data.windup + data.active_seconds:
            angle = lerpf(-1.0, 1.65, (sword_time-data.windup) / data.active_seconds)
        else:
            angle = lerpf(1.65, 0.25, (sword_time-data.windup-data.active_seconds) / data.recovery)
    var tint := Color("b9fff0") if heavy else Color.WHITE
    var factor := 1.4 if heavy else 1.0
    draw_set_transform(Vector2(direction*7,-25), angle*direction, Vector2(direction,1)*factor)
    WeaponArt.axe(self, tint)
    draw_rect(Rect2(-3,-1,6,5), Color("d6a070"))
    draw_set_transform(Vector2.ZERO)
    if sword_time >= data.windup and sword_time < data.windup + data.active_seconds:
        draw_set_transform(Vector2(0,-23),0,Vector2(direction,1))
        draw_arc(Vector2.ZERO, data.reach-5, -1.0, 0.65, 12, Color("b4ffdc") if heavy else Color("efcf99"), 4 if heavy else 2)
        if heavy:
            for i in 6:
                draw_rect(Rect2(22+i*13,10-(i%2)*6,8,3),Color("d7ffe2"))
        draw_set_transform(Vector2.ZERO)
