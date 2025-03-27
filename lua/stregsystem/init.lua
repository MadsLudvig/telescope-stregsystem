local stregsystem = {}

-- Execute shell command and return result
local function execute_command(command)
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	return string.gsub(tostring(result), "\n", "")
end

-- Safe function execution
local function try(f)
	local success, result = pcall(f)
	if success then
		return result
	end
end

-- Setup function to configure the system
stregsystem.setup = function(opts)
	stregsystem.config = {
		endpoint = opts.endpoint or "https://stregsystem.fklub.dk/api/",
		username = opts.username or "",
	}
end

-- Get member ID from username
local function get_member_id(username)
	return try(function()
		local result = execute_command(
			string.format([[curl -s -X GET "%smember/get_id?username=%s"]], stregsystem.config.endpoint, username)
		)
		return vim.json.decode(result).member_id
	end)
end

-- Get user balance
local function get_balance(member_id)
	return try(function()
		local result = execute_command(
			string.format([[curl -s -X GET "%smember/balance?member_id=%s"]], stregsystem.config.endpoint, member_id)
		)
		return tostring(tonumber(vim.json.decode(result).balance) / 100)
	end)
end

-- Buy a product
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
			local message = string.format("%s købte %s for %s", username, selection.text, selection.cost)
			if data.values.caffeine ~= 0 then
				message = message .. string.format("\n── du har %.1fmg koffein i blodet", data.values.caffeine)
			end
			if data.values.promille ~= 0.0 then
				message = message .. string.format("\n── du har %.2f‰ alkohol i blodet", data.values.promille)
			end
			vim.notify(message, "info", { title = "snacks-stregsystem" })
		else
			vim.notify("Whoops. Shit happened", "error", { title = "snacks-stregsystem" })
		end
	end)
end

-- Fetch products list
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

			table.insert(products, {
				idx = key,
				id = key,
				text = product_name,
				cost = product_price,
				name = product_name,
			})
		end
		return products
	end)
end

-- Main function to display and interact with products
stregsystem.stregsystem = function()
	local Snacks = require("snacks")

	local username = stregsystem.config.username
	local member_id = get_member_id(username)
	local balance = get_balance(member_id)
	local product_list = get_products()

	if member_id == nil and product_list ~= nil then
		vim.notify("Hvorfor bruger du et brugernavn der ikke eksisterer?", "error", { title = "snacks-stregsystem" })
		return
	elseif member_id == nil and product_list == nil then
		vim.notify(
			"Tror du ik lige du burde have internetforbindelse først?",
			"error",
			{ title = "snacks-stregsystem" }
		)
		return
	end

	return Snacks.picker({
		-- Finder function to prepare product items
		finder = function()
			return product_list or {}
		end,

		-- Custom layout configuration
		layout = {
			layout = {
				box = "horizontal",
				width = 78,
				height = 0.7,
				{
					box = "vertical",
					border = "rounded",
					title = string.format("StregSystemet ── %s ── %s𝓕$", username, balance),
					{ win = "input", height = 1, border = "bottom" },
					{ win = "list", border = "none" },
				},
			},
		},

		-- Custom formatting for picker items
		format = function(item, _)
			local ret = {}
			local a = Snacks.picker.util.align

			ret[#ret + 1] = { a(item.id, 4), "TelescopeResultsNumber" }
			ret[#ret + 1] = { " │ " }
			ret[#ret + 1] = { a(item.text, 55), "TelescopeResultsIdentifier" }
			ret[#ret + 1] = { " │ " }
			ret[#ret + 1] = { item.cost .. " kr", "TelescopeResultsFunction" }

			return ret
		end,

		-- Action to take when confirming a product
		confirm = function(picker, item)
			picker:close()

			local choice = vim.fn.confirm(string.format("Gennemfør køb af: %s", item.text), "&Yeah\n&Nej")
			if choice == 1 then
				buy_product(username, member_id, item)
			end
		end,
	})
end

return stregsystem
