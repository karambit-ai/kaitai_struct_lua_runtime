--
-- String decoder functions
--

local function safe_require_utf8()
	local package_exists, module = pcall(require, "lua-utf8")
	if not package_exists then
		return require("utf8")
	else
		return module
	end
end

local utf8 = safe_require_utf8()

local stringdecode = {}

-- From http://lua-users.org/wiki/LuaUnicode
local function utf8_to_32(utf8str)
	assert(type(utf8str) == "string")
	local res, seq, val = {}, 0, nil

	for i = 1, #utf8str do
		local c = string.byte(utf8str, i)
		if seq == 0 then
			table.insert(res, val)
			seq = c < 0x80 and 1
				or c < 0xE0 and 2
				or c < 0xF0 and 3
				or c < 0xF8 and 4 --c < 0xFC and 5 or c < 0xFE and 6 or
				or error("Invalid UTF-8 character sequence")
			val = bit.band(c, 2 ^ (8 - seq) - 1)
		else
			val = bit.bor(bit.lshift(val, 6), bit.band(c, 0x3F))
		end

		seq = seq - 1
	end

	table.insert(res, val)

	return res
end

function stringdecode.decode(str, encoding)
	local enc = encoding and encoding:lower() or "ascii"

	if enc == "ascii" then
		return str
	elseif enc == "utf-8" then
		local ok, code_points = pcall(utf8_to_32, str)
		if ok then
			return utf8.char(unpack(code_points))
		end
		-- NB: As a fallback, just return the string.
		return stringdecode.printableWithHex(str)
	else
		error("Encoding " .. encoding .. " not supported")
	end
end

function stringdecode.printableWithHex(str)
	local result = {}
	for i = 1, #str do
		local byte = string.byte(str, i)
		if byte >= 32 and byte <= 126 then
			table.insert(result, string.char(byte))
		else
			table.insert(result, string.format("\\x%02x", byte))
		end
	end
	return table.concat(result)
end

return stringdecode
