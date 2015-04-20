--=============================
-- LuaLoader
--
-- Author : Kurapica
-- Create Date : 2015/04/19
--=============================
_ENV = Module "System.Web.LuaLoader" "1.0.0"

fopen = io.open

__FileLoader__"lua"
__Unique__() class "LuaLoader" (function(_ENV)
	function LoadFile(self, path)
		local name = path:match("([_%w]+)%.%w+$")

		local f = fopen(path, "r")

		if f then
			local ct = f:read("*all")
			f:close()

			-- For simple, the file name must == the class name
			ct = ct .. ("\nreturn " .. name)

			return assert(loadstring(ct))()
		end
	end
end)