## Tool script for programmatically altering project settings.[br]
## Currently it ensures the constants defined in [enum Global.COLLISION_LAYERS] always match
## the layer names in [u]Project Settings > [member ProjectSettings.layer_names/2d_physics][/u]).
@tool
extends Node

func _ready() -> void:
	# Wrap everything into an `assert()`, so the compiler
	# would strip it out in release builds.
	assert((func() -> bool:
		if not Engine.is_editor_hint():
			return true
		
		# Open "Global.gd" and read its contents.
		var file: FileAccess = FileAccess.open(Global.get_script().resource_path, FileAccess.READ)
		var content: String = file.get_as_text()
		file.close()
		
		# Extract everything between `enum COLLISION_LAYERS {` and the closing `}`.
		# It's worth noting that the comments may contain the `}` character too,
		# so we'll have to work around that.
		# Pattern breakdown:
		# (?s)              -> Makes the dot (`.`) match any character including newlines (`\n`).
		# enum\s+           -> Seeks for the `enum` keyword and whitespaces after it.
		# COLLISION_LAYERS  -> Enum name.
		# \s*\{\s*          -> Skips whitespaces, the opening curly brace (`{`) and the trailing whitespaces.
		# (                 -> Main capturing group start.
		# (?:               -> Non-capturing group start.
		# [^#}]*#+[^\n]*\n  -> Option 1: Matches code leading to a comment, then the comment symbol #+,
		#                      then everything until the end of that line \n. This safely "swallows"
		#                      any closing curly braces (`}`) within comments.
		# |                 -> OR: Separates Option 1 from Option 2.
		# [^}]+             -> Option 2: Matches any characters as long as they are not a closing curly brace (`}`).
		# )*                -> Closes the non-capturing group and repeats it zero or more times.
		# )                 -> Main capturing group end.
		# (.*?)             -> "Lazy" search: capture everything until...
		# \s*\}             -> ... the first closing curly brace (`}`).
		var regex: RegEx = RegEx.new()
		regex.compile("(?s)enum\\s+COLLISION_LAYERS\\s*\\{\\s*((?:[^#}]*#+[^\\n]*\\n|[^}]+)*)\\s*\\}")
		content = regex.search(content).get_string(1)
		
		# Parse each line and extract pairs of layer names and comments.
		# Pattern breakdown:
		# (?m)      -> Multiline mode: makes `^` and `$` match at the start and end of any line
		#              (delimited by `\n)`, instead of the start and end of the whole enum string.
		# ^         -> Line start.
		# [ \t]*    -> Skips leading whitespaces and tabs.
		# (\w+)     -> Captures the layer name.
		# [^#\n]*   -> Skips everything until the `#` character or line end.
		# (?:       -> Non-capturing group start.
		# #+        -> Skips one or multiple `#` characters.
		# [ \t]*    -> Skips whitespaces and tabs before the comment text.
		# (.*)      -> Captures the comment text.
		# [ \t]*    -> Skips trailing whitespaces and tabs.
		# )?        -> Closes the group and marks it as optional (0 or 1 times).
		#              If there's no `#` after the enum member name, the entire block is skipped.
		# $         -> Line end.
		regex.compile("(?m)^[ \\t]*(\\w+)[^#\\n]*(?:#+[ \\t]*(.*)[ \\t]*)?$")
		var matches: Array[RegExMatch] = regex.search_all(content)
		
		# Use the result of `layer_name.capitalize()` as a layer name in the project settings.
		# If a comment was found, then override the name with the contents of that comment.
		var modified: bool = false
		for match: RegExMatch in matches:
			var layer_name: String = match.get_string(1)
			var description: String = match.get_string(2)
			if description.is_empty():
				description = layer_name.capitalize()
			var setting_name: String = "layer_names/2d_physics/layer_" + str(Global.COLLISION_LAYERS[layer_name])
			if ProjectSettings.get_setting(setting_name) != description:
				ProjectSettings.set_setting(setting_name, description)
				modified = true
		
		if modified:
			ProjectSettings.save()
		return true
	).call())
