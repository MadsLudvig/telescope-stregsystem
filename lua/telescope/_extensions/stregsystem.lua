local stregsystem = require("stregsystem")
return require("telescope").register_extension({
	setup = function(ext_config, _)
		stregsystem.setup(ext_config)
	end,
	exports = {
		stregsystem = stregsystem.stregsystem,
	},
})
