## Tracks persistent currency across runs.
## Coins earned in-game accumulate here for spending in the shop.
class_name Wallet
extends Node

var coins: int = 0
var lifetime_coins: int = 0

signal coins_changed(current: int, delta: int)


func add_coins(amount: int) -> void:
	coins += amount
	lifetime_coins += amount
	coins_changed.emit(coins, amount)


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins, -amount)
	return true


func can_afford(amount: int) -> bool:
	return coins >= amount


func reset() -> void:
	coins = 0
	lifetime_coins = 0


func to_dict() -> Dictionary:
	return {"coins": coins, "lifetime_coins": lifetime_coins}


func from_dict(data: Dictionary) -> void:
	coins = data.get("coins", 0)
	lifetime_coins = data.get("lifetime_coins", 0)
