extends CombatHurtbox
var head:=false
func receive(event: DamageEvent) -> void:
    var dragon: EnderDragon=get_parent()
    if not dragon.active or health.current<=0: return
    health.queue_damage(event.with_amount(ceili(event.amount*1.25)) if head and dragon.exposed() else event)
