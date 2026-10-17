class_name EmeraldWallet
extends Node
## Collection score is immutable when spending; only this separate ledger changes.
@onready var items: PlayerItems = get_parent().get_node("ItemEffects")
var carried: int = 0
var spent: int = 0

func available() -> int:
    return maxi(0, carried + items.emeralds - spent)

func try_spend(amount: int) -> bool:
    if amount <= 0 or available() < amount: return false
    spent += amount
    return true

func reset_to_entry(amount: int) -> void:
    carried = maxi(0, amount)
    spent = 0
