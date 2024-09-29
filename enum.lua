--
-- Each enum "value" is a table containing both a string label and an integer
-- value. When two enums are compared these labels and values are individually
-- compared.
--

local enum = {}

function enum.Enum(t)
	local e = { _enums = {} }

	for k, v in pairs(t) do
		e._enums[k] = {
			label = k,
			value = v,
		}
	end

	return setmetatable(e, {
		__index = function(table, key)
			return rawget(table._enums, key)
		end,

		__call = function(table, value)
			for _, v in pairs(table._enums) do
				if v.value == value then
					return v
				end
			end

			return nil
		end,

		__eq = function(lhs, rhs)
			for k, v in pairs(lhs._enums) do
				if v ~= rhs._enums[k] then
					return false
				end
			end

			return true
		end,
	})
end

--[[
    There are often times when we want to parse something as a bitfield. We
    can accomplish this by representing our bitfield as an enum and using
    this helper function to extract the entries.

    By default, we return the result as an array of only the bitfield flags that
    were determined to be present. If the `asTable` argument is set to true, we
    return a table mapping bitfield flag to a boolean value determining if the
    flag was set.
]]
function enum.parseFlags(data, bitfieldEnum, asTable)
	local asTable = asTable or false
	local parsedFlags = {}

	for flag, bitfield in pairs(bitfieldEnum) do
		local present = bit.band(data, bitfield) ~= 0
		if asTable and present then
			parsedFlags[flag] = true
		elseif asTable then
			parsedFlags[flag] = false
		elseif present then
			table.insert(parsedFlags, flag)
		end
	end

	return parsedFlags
end

return enum
