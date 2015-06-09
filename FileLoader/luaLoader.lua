--=============================
-- LuaLoader
--
-- Author : Kurapica
-- Create Date : 2015/04/19
--=============================
_ENV = Module "System.Web.LuaLoader" "1.0.0"

namespace "System.Web"

fopen = io.open

_DefineMatch = {
	"(%a+)%s*%(?%s*\"([_%w]+)\"",
	"(%a+)%s*%(?%s*'([_%w]+)'",
}

_TypeDefineWord = {
	class = true,
	interface = true,
	--enum = true,
	--struct = true,
	--namespace = true,
}

__FileLoader__"lua"
__Unique__() class "LuaLoader" {
	IFileLoader,

	LoadFile = function (self, path)
		local name = path:match("([_%w]+)%.%w+$"):lower()
		local tName = nil

		local f = fopen(path, "r")

		if f then
			local ct = f:read("*all")
			f:close()

			for _, match in ipairs(_DefineMatch) do
				for key, tarName in ct:gmatch(match) do
					if _TypeDefineWord[key] and tarName:lower() == name then
						tName = tarName
						break
					end
				end
				if tName then break end
			end

			if tName then
				ct = ct .. (Web.LineBreak .. "return " .. tName)
			end

			return assert(loadstring(ct))()
		end
	end
}