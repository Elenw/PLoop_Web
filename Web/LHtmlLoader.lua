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
tremove = table.remove
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

function parsePrintTemp(word)
	lhtmlLoader.ParsesPrintTempOk = true
	tinsert(lhtmlLoader.ParsesPrintTemp, word)
	return ""
end

function parsePrint(prev, printCode)
	if prev ~= "@" then
		local wordOk = true

		lhtmlLoader.ParsesPrintTemp = lhtmlLoader.ParsesPrintTemp or {}

		while printCode ~= "" do
			local head = printCode:sub(1, 1)
			lhtmlLoader.ParsesPrintTempOk = false

			if head == "." or head == ":" then
				printCode = printCode:gsub("^[%.:][%w_]+", parsePrintTemp)
				wordOk = false
			elseif head == "(" then
				printCode = printCode:gsub("^%b()", parsePrintTemp)
				wordOk = false
			elseif head == "[" then
				printCode = printCode:gsub("^%b[]", parsePrintTemp)
				wordOk = false
			elseif wordOk and head:match("[%w_]+") then
				printCode = printCode:gsub("^[%w_]+", parsePrintTemp)
			end

			if not lhtmlLoader.ParsesPrintTempOk then
				break
			end
		end

		local code = tconcat(lhtmlLoader.ParsesPrintTemp, "")

		lhtmlLoader.ParsesPrintTemp = nil

		return ([[%s]=] writer:Write(%s) writer:Write[=[%s]]):format(prev, code, printCode)
	end
end

function parsePrintParen(prev, printCode)
	if prev ~= "@" then
		return ([[%s]=] writer:Write%s writer:Write[=[]]):format(prev, printCode)
	end
end

function parseLine(prev, space, line)
	if prev == "@" and space == "" then return end
	if not(prev == "" or prev == "\n" or prev == "\r") then return end
	local generateSkip = false
	if prev == "" and not lhtmlLoader.GenerateRenderSkipFirst then generateSkip = true lhtmlLoader.GenerateRenderSkipFirst = true end
	return ([[]=] %s%s writer:Write[=[]]):format(
		generateSkip and "local __skipTheFirstRet = true " or "",
		line)
end

function parseLineWithKeyWord(prev, space, keyword, line)
	if prev == "@" and space == "" then return end
	if not(prev == "" or prev == "\n" or prev == "\r") then return end
	if _KeyWordMap[keyword] ~= nil then
		local generateSkip = false
		if prev == "" and not lhtmlLoader.GenerateRenderSkipFirst then generateSkip = true lhtmlLoader.GenerateRenderSkipFirst = true end
		return ([[]=] %s%s%s writer:Write[=[]]):format(
			generateSkip and "local __skipTheFirstRet = true " or "",
			keyword, line)
	end
end

function parseWebPart(ret, space, name, option)
	if ret == "@" and space == "" then return end
	local needSpace = ret == "" or ret == "\n" or ret == "\r"

	return ([[%s%s]=] if self.Render_%s then self:Render_%s(writer, space .. %q) else writer:Write(%q) end writer:Write[=[]]):format(
		ret, space, name, name, needSpace and space or "", option)
end

function parseEmbedPage(ret, space, name, option)
	if ret == "@" and space == "" then return end
	local needSpace = ret == "" or ret == "\n" or ret == "\r"

	return ([[%s%s]=] __FileLoader__.OutputPhysicalFiles(%q, writer, space .. %q, %q) writer:Write[=[]]):format(
		ret, space, name, needSpace and space or "", option)
end

function parseHtmlHelper(ret, space, name, param)
	if ret == "@" and space == "" then return end
	local needSpace = ret == "" or ret == "\n" or ret == "\r"
	param = param:sub(2, -2):gsub("^%s+", ""):gsub("%s+$", "")
	if param == "" then param = nil end

	return ([[%s%s]=] self:Render_%s(writer, space .. %q%s) writer:Write[=[]]):format(
		ret, space,	name,
		needSpace and space or "",
		param and ", " .. param or "")
end

function parseSpaceForLineInner(retSpace)
	if lhtmlLoader.GenerateRenderSkipFirst then
		return ("]=] if not __skipTheFirstRet then writer:Write(%q) writer:Write(space) else __skipTheFirstRet = false end writer:Write[=["):format(retSpace)
	else
		return ("%s]=] writer:Write(space) writer:Write[=["):format(retSpace)
	end
end

function parseSpaceForLine(data)
	return "[=[" .. data:gsub("[\n\r]+%s*", parseSpaceForLineInner) .. "]=]"
end

function generateRender(template, part, param)
	lhtmlLoader.GenerateRenderSkipFirst = false

	local args = param and param:gsub("^%s+", ""):gsub("%s+$", "")
	if args == "" then args = nil end

	-- Parse lua code
	template = template:gsub("(.?)([ 	]*)@>([^\n\r]+)", parseLine)
	template = template:gsub("(.?)([ 	]*)@%s*(%w+)([^\n\r]*)", parseLineWithKeyWord)

	-- Parse print code
	template = template:gsub("(.?)@%s*(%b())", parsePrintParen)
	template = template:gsub("(.?)@%s*([_%w]+[^\n\r]+)", parsePrint)

	-- Parse html helper
	template = template:gsub("(.?)([ 	]*)@%s*{%s*([_%w]+)%s*(%b())%s*}", parseHtmlHelper)

	-- Parse web part
	template = template:gsub("(.?)([ 	]*)@%s*{%s*([_%w]+)%s*(.-)%s*}", parseWebPart)

	-- Parse embed page
	template = template:gsub("(.?)([ 	]*)@%s*%[%s*([^%s:]+)%s*(.-)%s*%]", parseEmbedPage)

	-- Format code
	template = template:gsub("@@", "@")
	template = template:gsub("writer:Write%[=%[([\n\r])", "%0%1")

	template = ("function %s(self, writer, space%s) space = space or \"\" writer:Write[=[%s]=] end"):format(part and "Render_" .. part or "Render", args and ", " .. args or "", template)

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
					assert(not lhtmlLoader.Abstract, ("%s - the page is an abstract page, can't inherit other pages."):format(header))

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
						for p in v:gmatch("[^%s,]+") do
							local itf = Reflector.GetNameSpaceForName(p)
							if Reflector.IsInterface(itf) then
								tinsert(lhtmlLoader.Definition, itf)
							else
								local loader = lhtmlLoader
								itf = __FileLoader__.LoadPhysicalFiles(v)
								lhtmlLoader = loader
								if Reflector.IsInterface(itf) then
									tinsert(lhtmlLoader.Definition, itf)
								else
									error(("%s - interface %s not existed."):format(header, p))
								end
							end
						end
					elseif Reflector.IsInterface(v) then
						tinsert(lhtmlLoader.Definition, v)
					else
						error(("%s - extend format error."):format(header))
					end
				elseif k == "abstract" and v then
					lhtmlLoader.Abstract = true
					for i = #(lhtmlLoader.Definition), 1, -1 do
						if Reflector.IsClass(lhtmlLoader.Definition[i]) then
							tremove(lhtmlLoader.Definition, i)
						end
					end
				elseif k == "unique" and v then
					lhtmlLoader.UniqueClass = true
				elseif k == "cache" and v then
					lhtmlLoader.CacheClass = true
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

			ct = ct:gsub("\r\n", "\n")

			-- Get line break
			local lb = ct:match("[\n\r]")

			-- Check the header
			ct = ct:gsub("^@(%b{})", parsePageHeader):gsub("^[\n\r%s]+", ""):gsub("[\n\r%s]$", "")

			-- Create or modify the target class with page header
			if self.Abstract or Reflector.IsInterface(target) then
				assert(not target or Reflector.IsInterface(target), ("The %s is a class, can't mark as abstract."):format(name))
				if target then
					interface(target)(self.Definition)
				else
					__NameSpace__(self.NameSpace)
					target = Reflector.GetDefinitionEnvironmentOwner( interface(name)(self.Definition) )
				end
			else
				if self.UniqueClass then __Unique__() end
				if self.CacheClass then __Cache__() end
				if target then
					class(target)(self.Definition)
				else
					__NameSpace__(self.NameSpace)
					target = Reflector.GetDefinitionEnvironmentOwner( class(name)(self.Definition) )
				end
			end

			self.DefinePart = {}

			-- parse global lua code
			ct = ct:gsub("(.?)@%s*{%s*[\n\r](.-)[\n\r]}", parseLuaCode)
			-- parse html helper
			ct = ct:gsub("(.?)@%s*([_%w]+)%s*(%b())%s*{%s*[\n\r](.-)[\n\r]}", parseHtmlHelperDefine)
			-- parse web part
			ct = ct:gsub("(.?)@%s*([_%w]+)%s*{%s*[\n\r](.-)[\n\r]}", parseWebPartDefine)

			-- Generate the Main Html Page
			if Reflector.IsClass(target) then
				local superCls = Reflector.GetSuperClass(target)
				if not (superCls and Reflector.IsExtendedInterface(superCls, IPage)) then
					tinsert(self.DefinePart, generateRender((ct:gsub("^[\n\r%s]+", ""):gsub("[\n\r%s]$", ""))))
				end
			end

			ct = tconcat(self.DefinePart, lb)

			Debug("Generate definition for %s :", name)
			Debug("\n%s", ct)

			-- Recode the target class
			if Reflector.IsClass(target) then
				class (target) ( ct )
			else
				interface (target) ( ct )
			end

			SetLhtmlLoader(nil)
		end

		return target
	end
end)