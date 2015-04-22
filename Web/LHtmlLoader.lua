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
tconcat = table.concat

_KeyWordMap = {
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["for"] = true,
	["if"] = true,
	["elseif"] = true,
	["return"] = true,
	["then"] = true,
	["repeat"] = true,
	["while"] = true,
	["until"] = true,
	["end"] = true,
	["function"] = true,
	["local"] = true,
	["in"] = true,
}

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

function parseLineWithKeyWord(keyword, line)
	if _KeyWordMap[keyword] then
		return ([[]=] %s%s writer:Write[=[]]):format(keyword, line)
	end
end

function parseWebPart(ret, space, name, option)
	if ret == "@" then
		if space and #space > 0 then
			ret = ""
		else
			return
		end
	end
	if option == "" then option = nil end
	if option and option:match("^:") then option = option:sub(2, -1) end
	local temp = option or ("%s@{%s}"):format(space, name)
	lhtmlLoader.Definition["Render_" .. name] = function(self, writer) writer:Write( temp ) end

	return ([[%s%s]=] self:Render_%s(writer, space .. %q) writer:Write[=[]]):format(ret, space, name, #ret > 0 and space or "")
end

function parseEmbedPage(ret, space, name, option)
	if ret == "@" then
		if space and #space > 0 then
			ret = ""
		else
			return
		end
	end
	if option == "" then option = nil end
	if option and option:match("^:") then option = option:sub(2, -1) end
	local temp = option or ("%s@{%s}"):format(space, name)

	return ([[%s%s]=] __FileLoader__.OutputPhysicalFiles(%q, writer, space .. %q, %q) writer:Write[=[]]):format(ret, space, name, #ret > 0 and space or "", temp)
end

function parseHtmlHelper(ret, space, name, param)
	if ret == "@" then
		if space and #space > 0 then
			ret = ""
		else
			return
		end
	end
	param = param:sub(2, -2):gsub("^%s+", ""):gsub("%s+$", "")
	if param == "" then param = nil end

	return ([[%s%s]=] self:Render_%s(writer, %s%q%s) writer:Write[=[]]):format(
		ret, space,	name,
		#ret > 0 and "space .. " or "",
		#ret > 0 and space or "",
		param and ", " .. param or "")
end

function parseSpaceForLine(data)
	return "[=[" .. data:gsub("[\n\r]+%s*", "%0]=] writer:Write(space) writer:Write[=[") .. "]=]"
end

function generateRender(template, part, param)
	local args = param and param:gsub("^%s+", ""):gsub("%s+$", "")
	if args == "" then args = nil end

	template = ("function %s(self, writer, space%s) space = space or \"\" writer:Write[=[%s]=] end"):format(part and "Render_" .. part or "Render", args and ", " .. args or "", template)

	-- Parse lua code
	template = template:gsub("[\n\r]%s*@>([^\n\r]+)", parseLine)
	template = template:gsub("[\n\r]%s*@%s*(%w+)([^\n\r]*)", parseLineWithKeyWord)

	-- Parse print code
	template = template:gsub("(.?)@%s*([%w_%.:]*%b\(\))", parsePrint)
	template = template:gsub("(.?)@%s*([%w_%.:]+)", parsePrint)

	-- Parse html helper
	template = template:gsub("([\n\r@]?)(%s*)@%s*{%s*([_%w]+)%s*(%b\(\))%s*}", parseHtmlHelper)

	-- Parse web part
	template = template:gsub("([\n\r@]?)(%s*)@%s*{%s*([_%w]+)%s*(.-)%s*}", parseWebPart)

	-- Parse embed page
	template = template:gsub("([\n\r@]?)(%s*)@%s*%[%s*([^%s:]+)%s*(.-)%s*%]", parseEmbedPage)

	-- Format code
	template = template:gsub("@@", "@")
	template = template:gsub("writer:Write%[=%[([\n\r])", "%0%1")

	-- handle the space
	template = template:gsub("%[=%[(.-)%]=%]", parseSpaceForLine)
	template = template:gsub("%s*writer:Write%[=%[%]=%]%s*", " ")

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
						tinsert(lhtmlLoader.Definition, v)
					elseif type(v) == "string" then
						local cls = Reflector.GetNameSpaceForName(v)
						if Reflector.IsClass(cls) then
							tinsert(lhtmlLoader.Definition, cls)
						else
							local loader = lhtmlLoader
							local cls = __FileLoader__.LoadPhysicalFiles(v)
							lhtmlLoader = loader
							if Reflector.IsClass(cls) then
								tinsert(lhtmlLoader.Definition, cls)
							else
								error(("%s - the master page can't be found."):format(header))
							end
						end
					else
						error(("%s - inherit format error."):format(header))
					end
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
	if not prev or prev == "" or prev == "\n" or prev == "\r" then
		tinsert(lhtmlLoader.DefinePart, code)
		return ""
	end
end

function parseWebPartDefine(prev, name, code)
	if not prev or prev == "" or prev == "\n" or prev == "\r" then
		local space = code:match("^%s+")
		if space and #space > 0 then
			code = code:gsub("^%s+", ""):gsub("([\n\r]+)"..space, "%1"):gsub("[\n\r%s]+$", "")
		end

		tinsert(lhtmlLoader.DefinePart, generateRender(code, name))
		return ""
	end
end

function parseHtmlHelperDefine(prev, name, param, code)
	if not prev or prev == "" or prev == "\n" or prev == "\r" then
		local space = code:match("^%s+")
		if space and #space > 0 then
			code = code:gsub("^%s+", ""):gsub("([\n\r]+)"..space, "%1"):gsub("[\n\r%s]+$", "")
		end

		tinsert(lhtmlLoader.DefinePart, generateRender(code, name, param:sub(2, -2)))
		return ""
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

			-- Get line break
			local lb = ct:match("[\n\r]")

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
			self.DefinePart = {}

			-- parse global lua code
			ct = ct:gsub("(.?)@%s*{%s*[\n\r](.-)[\n\r]}", parseLuaCode)
			-- parse html helper
			ct = ct:gsub("(.?)@%s*([_%w]+)%s*(%b\(\))%s*{%s*[\n\r](.-)[\n\r]}", parseHtmlHelperDefine)
			-- parse web part
			ct = ct:gsub("(.?)@%s*([_%w]+)%s*{%s*[\n\r](.-)[\n\r]}", parseWebPartDefine)

			-- Generate the Main Html Page
			local superCls = Reflector.GetSuperClass(target)
			if not (superCls and Reflector.IsExtendedInterface(superCls, IPage)) then
				tinsert(self.DefinePart, generateRender((ct:gsub("^[\n\r%s]+", ""):gsub("[\n\r%s]$", ""))))
			end

			ct = tconcat(self.DefinePart, lb)

			Debug("Generate class definition for %s :", name)
			Debug(ct)

			-- Recode the target class
			if next(self.Definition) then class (target) (self.Definition) end
			class (target) ( ct )

			SetLhtmlLoader(nil)
		end

		return target
	end
end)