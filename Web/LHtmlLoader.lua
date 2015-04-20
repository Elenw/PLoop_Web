--=============================
-- LHtmlLoader
--
-- Author : Kurapica
-- Create Date : 2015/04/19
--=============================
_ENV = Module "System.Web.LHtmlLoader" "1.0.0"

import "System"

fopen = io.open
tinsert = table.insert

_PageSpaceMap = {}

local lhtmlLoader = nil

function SetLhtmlLoader(loader) lhtmlLoader = loader end

function parsePrint(prev, printCode)
	if prev ~= "@" then
		return ([[%s]=] writer:Write(%s) writer:Write[=[]]):format(prev, printCode)
	end
end

function parseLine(line)
	return ([[]=] %s writer:Write[=[]]):format(line)
end

function parseWebPart(ret, space, name, option)
	if option == "" then option = nil end
	if option and option:match("^:") then option = option:sub(2, -1) end
	local temp = option or ("%s@{%s}"):format(space, name)
	lhtmlLoader.Definition["Render_" .. name] = function(self, writer) writer:Write( temp ) end
	if #ret > 0 then
		lhtmlLoader.TabMap[name] = space
		return ([[%s]=] self:Render_%s(writer) writer:Write[=[]]):format(ret, name)
	else
		return ([[%s%s]=] self:Render_%s(writer) writer:Write[=[]]):format(ret, space, name)
	end
end

function generateRender(template, part)
	local space = part and lhtmlLoader.TabMap[part]
	if space then template = space .. template:gsub("[\n\r]", "%1" .. space) end

	template = ("function %s(self, writer) writer:Write[=[%s]=] end"):format(part and "Render_" .. part or "Render", template)

	-- Parse lua code
	template = template:gsub("[\n\r]%s*@>([^\n\r]+)", parseLine)

	-- Parse print code
	template = template:gsub("(.?)@%s*([%w_%.]*%b\(\))", parsePrint)
	template = template:gsub("(.?)@%s*([%w_%.]+)", parsePrint)

	-- Parse web part
	template = template:gsub("([\n\r]?)(%s*)@%s*{%s*([_%w]+)%s*(.-)%s*}", parseWebPart)

	-- Format code
	template = template:gsub("@@", "@")
	template = template:gsub("%s*writer:Write%[=%[%s*%]=%]%s*", " ")
	template = template:gsub("writer:Write%[=%[([\n\r])", "%0%1")

	return template
end

function parsePageHeader(header)
	if not header:match("[\n\r]") then
		local define = assert(loadstring("return " .. header))()
		assert(type(define) == "table", "Page header must be a lua table.")

		for k, v in pairs(define) do
			if type(k) == "string" then
				k = k:lower()
				if k == "namespace" then
					lhtmlLoader.NameSpace = v
				elseif k == "inherit" then
					if Reflector.IsClass(v) then
						lhtmlLoader.SuperClass = v
					elseif type(v) == "string" then
						local cls = Reflector.GetNameSpaceForName(v)
						if Reflector.IsClass(cls) then
							lhtmlLoader.SuperClass = cls
						else
							local loader = lhtmlLoader
							local cls = __FileLoader__.LoadPhysicalFiles(v)
							lhtmlLoader = loader
							if Reflector.IsClass(cls) then
								lhtmlLoader.SuperClass = cls
							else
								error(("%s - the master page can't be found."):format(header))
							end
						end
					else
						error(("%s - inherit format error."):format(header))
					end
					if lhtmlLoader.SuperClass then tinsert(lhtmlLoader.Definition, lhtmlLoader.SuperClass) end
				elseif k == "extend" then
					if type(v) == "string" then
						for p in v:gmatch("[%._%w]+") do
							local itf = Reflector.GetNameSpaceForName(p)
							if Reflector.IsInterface(itf) then
								tinsert(lhtmlLoader.Definition, itf)
							else
								error(("%s - interface %s not existed."):format(header, p))
							end
						end
					elseif Reflector.IsInterface(v) then
						tinsert(lhtmlLoader.Definition, v)
					else
						error(("%s - extend format error."):format(header))
					end
				end
			end
		end

		return ""
	end
end

function parseLuaCode(prev, code)
	if not prev or prev == "" or prev == "\n" or prev == "\r" then return code end
end

function parseWebPartDefine(prev, name, code)
	if not prev or prev == "" or prev == "\n" or prev == "\r" then
		local space = code:match("^%s+")
		if space and #space > 0 then
			code = code:gsub("^%s+", ""):gsub("([\n\r]+)"..space, "%1"):gsub("[\n\r%s]+$", "")
		end

		return generateRender(code, name)
	end
end

__FileLoader__"lhtml"
class "LHtmlLoader" (function(_ENV)

	function LoadFile(self, path, target)
		local name = path:match("([_%w]+)%.%w+$")

		local f = fopen(path, "r")

		if f then
			SetLhtmlLoader(self)

			local ct = f:read("*all")
			f:close()

			self.Definition = { IPage }

			-- Check the header
			ct = ct:gsub("^@(%b{})", parsePageHeader):gsub("^[\n\r%s]+", ""):gsub("[\n\r%s]$", "")

			-- Create or modify the target class with page header
			if target then
				class(target)(self.Definition)
			else
				__NameSpace__(self.NameSpace)
				target = Reflector.GetDefinitionEnvironmentOwner( class(name)(self.Definition) )
			end

			self.Definition = {}

			local superCls = Reflector.GetSuperClass(target)
			if superCls and _PageSpaceMap[superCls] then
				_PageSpaceMap[target] = Reflector.Clone(_PageSpaceMap[superCls])
			end

			self.TabMap = _PageSpaceMap[target] or {}

			-- Generate the Definition Body
			if self.SuperClass then
				-- parse the lua code
				ct = ct:gsub("(.?)@%s*{%s*[\n\r](.-)[\n\r]}", parseLuaCode)

				-- parse web part
				ct = ct:gsub("(.?)@%s*([_%w]+)%s*{%s*[\n\r](.-)[\n\r]}", parseWebPartDefine)
			else
				ct = generateRender(ct)
			end

			if next(self.TabMap) then _PageSpaceMap[target] = self.TabMap end

			-- Recode the target class
			if next(self.Definition) then class (target) (self.Definition) end
			class (target) ( ct )

			SetLhtmlLoader(nil)
		end

		return target
	end
end)