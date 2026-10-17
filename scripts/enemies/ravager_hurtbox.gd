extends CombatHurtbox

func receive(event: DamageEvent) -> void:
    var boss := get_parent() as RavagerEnemy
    if not boss.active or boss.health.current<=0: return
    var damage := event.amount if boss.exposed() else maxi(1,floori(event.amount*boss.tuning().armor_multiplier))
    health.queue_damage(event.with_amount(damage))
