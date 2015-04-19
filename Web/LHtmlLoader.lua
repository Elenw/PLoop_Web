--=============================
-- LHtmlLoader
--
-- Author : Kurapica
-- Create Date : 2015/04/19
--=============================
_ENV = Module "System.Web.LHtmlLoader" "1.0.0"

fopen = io.open

_PageSpaceMap = {}

function parsePrint(printCode) return ([[]=] writer:Write(%s) writer:Write[=[]]):format(printCode) end

function parsePrintWING(printCode) return ([[]=] writer:Write(%s) writer:Write[=[]]):format(printCode:sub(2, -2)) end

function parseLine(line) return ([[]=] %s writer:Write[=[]]):format(line) end

local _Def = nil
local _Map = nil

function parsePartHtml(ret, space, name)
	local temp = ("%s@{%s}"):format(space, name)
	_Def["Render_" .. name] = function(self, writer) writer:Write( temp ) end
	if #ret > 0 then
		_Map[name] = space
		return ([[%s]=] self:Render_%s(writer) writer:Write[=[]]):format(ret, name)
	else
		return ([[%s%s]=] self:Render_%s(writer) writer:Write[=[]]):format(ret, space, name)
	end
end

function generateRender(definiton, tabMap, template, partHtml)
	_Def = definiton
	_Map = tabMap

	local space = partHtml and tabMap[partHtml]
	if space then template = space .. template:gsub("[\n\r]", "%1" .. space) end

	template = ([[return function(self, writer) writer:Write[=[%s]=] end]]):format(template)

	template = template:gsub("@=([%w_%.]+)", parsePrint)
	template = template:gsub("@=(%b{})", parsePrintWING)
	template = template:gsub("[\n\r]?%s*@@([^\n\r]+)", parseLine)
	template = template:gsub("([\n\r]?)(%s*)@{([_%w]+)}", parsePartHtml)
	template = template:gsub("%s*writer:Write%[=%[%s*%]=%]%s*", " ")
	template = template:gsub("writer:Write%[=%[([\n\r])", "%0%1")

	definiton[partHtml and "Render_" .. partHtml or "Render"] = assert(loadstring(template))()

	_Def = nil
	_Map = nil
end

__FileLoader__"lhtml"
__Unique__() class "LHtmlLoader" (function(_ENV)

	function LoadFile(self, path, target)
		local name = path:match("([_%w]+)%.%w+$")

		local f = fopen(path, "r")

		if f then
			local ct = f:read("*all")
			f:close()

			local definiton = { IPage }

			local superCls = Reflector.GetSuperClass(target)
			if superCls and _PageSpaceMap[superCls] then
				_PageSpaceMap[target] = Reflector.Clone(_PageSpaceMap[superCls])
			end

			local tabMap = _PageSpaceMap[target] or {}

			-- Check if is web part
			if self.HasMasterPage then
				for partHtml, content in ct:gmatch("@{([_%w]+)[\n\r](.-)[\n\r]}") do
					local space = content:match("^%s+")
					if space then content = content:gsub("^%s+", ""):gsub("([\n\r]+)"..space, "%1"):gsub("([\n\r]+)%s+$", "%1") end

					generateRender(definiton, tabMap, content, partHtml)
				end
			else
				generateRender(definiton, tabMap, ct)
			end

			if next(tabMap) then _PageSpaceMap[target] = tabMap end

			-- Recode the target class
			class (target) ( definiton )

			return target
		else
			error(("Lua Page file not found for %s."):format(tostring(target)))
		end
	end
end)