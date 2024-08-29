class_name MyResource
extends Resource

var database: Database = preload("res://assets/resources/database.tres")

func load():
	var card = database.cards["Aragorn"]
