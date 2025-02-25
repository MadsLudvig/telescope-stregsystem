local stregsystem = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
--
local title = "telescope-stregsystem"

stregsystem.setup = function(opts)
	stregsystem.config = {
		endpoint = opts.endpoint or "https://stregsystem.fklub.dk/api/",
		username = opts.username or "",
	}
end

local function execute_command(command)
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	return string.gsub(tostring(result), "\n", "")
end

local function try(f)
	local success, result = pcall(f)
	if success then
		return result
	end
end

-- Function to get user ID from username
local function get_member_id(username)
	return try(function()
		local result = execute_command(
			string.format([[curl -s -X GET "%smember/get_id?username=%s"]], stregsystem.config.endpoint, username)
		)
		return vim.json.decode(result).member_id
	end)
end

-- Function to get user balance
local function get_balance(member_id)
	return try(function()
		local result = execute_command(
			string.format([[curl -s -X GET "%smember/balance?member_id=%s"]], stregsystem.config.endpoint, member_id)
		)
		return tostring(tonumber(vim.json.decode(result).balance) / 100)
	end)
end
-- Function to buy a product
local function buy_product(username, member_id, selection)
	try(function()
		local request_body = vim.fn.json_encode({
			room = 10,
			buystring = username .. " " .. selection.id,
			member_id = member_id,
		})
		local result = execute_command(
			string.format(
				[[curl -s --location '%ssale' --header 'Content-Type: application/json' --data '%s']],
				stregsystem.config.endpoint,
				request_body
			)
		)
		local data = vim.json.decode(result)

		if data.status == 200 then
			local message = string.format("%s købte %s for %s", username, selection.name, selection.cost)
			if data.values.caffeine ~= 0 then
				message = message .. string.format("\n── du har %.1fmg koffein i blodet", data.values.caffeine)
			end
			if data.values.promille ~= 0.0 then
				message = message .. string.format("\n── du har %.2f‰ alkohol i blodet", data.values.promille)
			end
			require("notify")(message, vim.log.levels.INFO, { title = title })
		else
			require("notify")("telescope-stregsystem: Der skete en fejl", vim.log.levels.ERROR, { title = title })
		end
	end)
end

-- Function to fetch products list
local function get_products()
	return try(function()
		local result = execute_command(
			string.format([[curl -s -X GET "%sproducts/active_products?room_id=10"]], stregsystem.config.endpoint)
		)
		local data = vim.json.decode(result)

		if data == nil then
			return nil
		end

		local products = {}
		for key, value in pairs(data) do
			local product_name = value.name
			product_name = string.lower(product_name:gsub("<[^>]+>", ""))
			product_name = product_name:match("^%s*(.-)%s*$")
			local product_price = string.format("%.2f", tonumber(value.price / 100))

			-- Adding the formatted data to the products table
			table.insert(products, { key, product_name, tostring(product_price) })
		end
		return products
	end)
end

local function make_entry(opts, results)
	local id_width = 0
	local name_width = 0

	-- Calculate dynamic widths based on the length of the longest entry in each field
	for _, entry in ipairs(results) do
		id_width = math.max(id_width, #tostring(entry[1]))
		name_width = math.max(name_width, #tostring(entry[2]))
	end

	local displayer = require("telescope.pickers.entry_display").create({
		separator = "  │  ",
		items = {
			{ width = 4 }, -- Width will be calculated dynamically
			{ width = name_width }, -- Width will be calculated dynamically
			{ remaining = true },
		},
	})

	local make_display = function(entry)
		return displayer({
			{ entry.id, "TelescopeResultsNumber" },
			{ entry.name, "TelescopeResultsIdentifier" },
			{ entry.cost, "TelescopeResultsFunction" },
		})
	end

	return function(entry)
		return require("telescope.make_entry").set_default_entry_mt({
			id = entry[1],
			name = entry[2],
			cost = entry[3],
			ordinal = entry[1] .. " " .. entry[2],
			display = make_display,
		}, opts)
	end
end

-- Function to display products and handle buying
stregsystem.stregsystem = function(opts)
	opts = opts or {}
	opts = require("telescope.themes").get_dropdown(opts)

	local username = stregsystem.config.username
	local member_id = get_member_id(username)
	local balance = get_balance(member_id)
	local product_list = get_products()

	if member_id == nil and product_list ~= nil then
		require("notify")("Forkert brugernavn. Omkonfigurer!!", vim.log.levels.ERROR, { title = title })
		return
	elseif member_id == nil and product_list == nil then
		require("notify")("Ingen forbindelse til serveren!", vim.log.levels.WARN, { title = title })
		return
	end

	pickers
		.new(opts, {
			prompt_title = string.format("StregSystemet ── %s ── %s𝓕$", username, balance),
			finder = finders.new_table({
				results = product_list,
				entry_maker = make_entry(opts, product_list),
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(bufnr, _)
				actions.select_default:replace(function()
					actions.close(bufnr)
					local selection = action_state.get_selected_entry()
					local choice =
						vim.fn.confirm(string.format("Gennemfør køb af: %s", selection.name), "&Yeah\n&Nej")
					if choice == 1 then
						buy_product(username, member_id, selection)
					end
				end)
				return true
			end,
		})
		:find()
end
return stregsystem
