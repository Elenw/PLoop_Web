--=============================
-- LHtmlLoader
--
-- Author : Kurapica
-- Create Date : 2015/05/10
--=============================
_ENV = Module "System.Web.LHtmlLoader" "1.1.0"

import "System"

__FileLoader__"lhtml"
class "LHtmlLoader" {
	LoadFile = function (self, path, target)
		local name = path:match("([_%w]+)%.%w+$")

		local f = fopen(path, "r")

		if f then
			SetLhtmlLoader(self)

			self.Definition = { IPage }

			local lines = f:lines()

			-- Check first line as page declaration
			local line = lines()
			local matched

			if line then
				-- @{ namespace = "xxx", inherit="/xxx/xxx", extend="/xxx/xxx,IExample", abstract=true, cache=true, unique=true}
				line, matched = line:gsub("^@(%b{})", parsePageHeader)

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

				self.Definition = nil
				self.Lines = lines
				self.LuaCode = {}

				local main = {}

				while line do
					line = line:gsub("%s+$", "")

					if line ~= "" then
						-- parse global lua code
						if matched == 0 then
							line, matched = line:gsub("^@%s*{$", parseLuaCode)
						end

						-- parse html helper
						if matched == 0 then
							line, matched = line:gsub("^@%s*([_%w]+)%s*(%b())%s*{$", parseHtmlHelperDefine)
						end

						-- parse web part
						if matched == 0 then
							line, matched = line:gsub("^@%s*([_%w]+)%s*{$", parseWebPartDefine)
						end

						-- Main part
						if matched == 0 then
							tinsert(main, parsePageLine(line))
						end
					end

					line = lines()
				end

				-- Generate the Main Html Page
				if Reflector.IsClass(target) then
					local superCls = Reflector.GetSuperClass(target)
					if not (superCls and Reflector.IsExtendedInterface(superCls, IPage)) then
						local codes = self.LuaCode
						tinsert(codes, [[function Render(self, writer, space) space = space or ""]])
						for _, line in ipairs(main) do tinsert(codes, line) end
						tinsert(codes, "end")
					end
				end

				local define = tconcat(self.LuaCode, WebSettings.LineBreak)
				Debug("Generate definition for %s :", name)
				Debug(define)

				-- Recode the target class
				if Reflector.IsClass(target) then
					class (target) ( define )
				else
					interface (target) ( define )
				end
			end

			f:close()

			SetLhtmlLoader(nil)
		end

		return target
	end
}

-------------------------------
-- Module
-------------------------------
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

--[======================[
namespace - The namespace of the page
inheirt - The master page of the page
extend - The HtmlHelper or other interface that extened by the page
abstract - If true the page is used as HtmlHelper as an interface
cache - Mark the page class as __Cache__
unique - Mark the page class as __Unique__
--]======================]
function parsePageHeader(header)
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
end

--[======================[
@self.Data
@(self.Data)
@>x = x + 123
@if some then
@{webpart}
@{htmlhelper(params)}
@[url]
--]======================]
function parsePageLine(line)
	local newline

	lhtmlLoader.SpaceHandled = false

	-- Parse lua code
	newline = line:gsub("^%s*@>(.*)$", parseLine)
	if newline ~= line then return newline end
	newline = line:gsub("^%s*@%s*(%w+)(.*)$", parseLineWithKeyWord)
	if newline ~= line then return newline end

	-- Parse print code
	line = line:gsub("(.?)@%s*(%b())", parsePrintParen)
	line = line:gsub("(.?)@%s*([_%w]+.+)", parsePrint)

	-- Parse html helper
	line = line:gsub("(.?)(%s*)@%s*{%s*([_%w]+)%s*(%b())%s*}", parseHtmlHelper)

	-- Parse web part
	line = line:gsub("(.?)(%s*)@%s*{%s*([_%w]+)%s*(.-)%s*}", parseWebPart)

	-- Parse embed page
	line = line:gsub("(.?)(%s*)@%s*%[%s*([^%s:]+)%s*(.-)%s*%]", parseEmbedPage)

	-- Format code
	line = line:gsub("@@", "@")

	if not lhtmlLoader.SpaceHandled then
		line = [[writer:Write(space) writer:Write[=[]] .. line
	end

	line = line .. ([[]=] writer:Write(%q)]]):format(WebSettings.LineBreak)
	line = line:gsub("%s*writer:Write%[=%[%]=%]%s*", " ")

	return line
end

--[======================[
@{
	-- global lua code block
}
--]======================]
function parseLuaCode()
	local codes = self.LuaCode
	local prev
	for line in self.Lines do
		line = line:gsub("%s+$", "")

		if line == "}" then return end

		tinsert(codes, line)
	end
	error("'@{' global lua code block must have an end '}'.")
end

--[======================[
@name(params){
	-- html helpler block
}
--]======================]
function parseHtmlHelperDefine(name, param)
	local codes = self.LuaCode
	local prev
	param = param:sub(2, -2)

	tinsert(codes, ([[function Render_%s(self, writer, space, %s) space = space or ""]]):format(name, param))

	for line in self.Lines do
		line = line:gsub("%s+$", "")
		if not prev then prev = "^" .. (line:match("^%s+") or "") end
		if prev then line = line:gsub(prev, "") end

		if line == "}" then
			tinsert(codes, "end")
			return
		end

		tinsert(codes, parsePageLine(line))
	end
	error(("'@%s(%s){' html helper block must have an end '}'."):format(name, param))
end

--[======================[
@name{
	-- web part block
}
--]======================]
function parseWebPartDefine(name)
	local codes = self.LuaCode
	local prev

	tinsert(codes, ([[function Render_%s(self, writer, space) space = space or ""]]):format(name))

	for line in self.Lines do
		line = line:gsub("%s+$", "")
		if not prev then prev = "^" .. (line:match("^%s+") or "") end
		if prev then line = line:gsub(prev, "") end

		if line == "}" then
			tinsert(codes, "end")
			return
		end

		tinsert(codes, parsePageLine(line))
	end
	error(("'@%s{' web part block must have an end '}'."):format(name))
end

--[======================[
@> lua line
--]======================]
function parseLine(line)
	return line
end

--[======================[
@if xxxx lua line start with keywords
--]======================]
function parseLineWithKeyWord(keyword, line)
	if _KeyWordMap[keyword] ~= nil then return keyword .. line end
end

--[======================[
@("Hello" .. self.Name)
--]======================]
function parsePrintParen(prev, printCode)
	if prev ~= "@" then
		return ([[%s]=] writer:Write(tostring%s) writer:Write[=[]]):format(prev, printCode)
	end
end


--[======================[
@self.Items:Get(1).Name
--]======================]
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

--[======================[
@{body this should be a body part}
--]======================]
function parseWebPart(ret, space, name, option)
	if ret == "@" and space == "" then return end
	if  ret == "" then
		lhtmlLoader.SpaceHandled = true
		return ([[if self.Render_%s then self:Render_%s(writer, space .. %q) else writer:Write(space) writer:Write(%q) end writer:Write[=[]]):format(
			name, name, space, option)
	else
		return ([[%s%s]=] if self.Render_%s then self:Render_%s(writer, space) else writer:Write(%q) end writer:Write[=[]]):format(
			ret, space, name, name, option)
	end
end

--[======================[
@[url get web part from other pages]
--]======================]
function parseEmbedPage(ret, space, name, option)
	if ret == "@" and space == "" then return end
	if ret == "" then
		lhtmlLoader.SpaceHandled = true
		return ([[__FileLoader__.OutputPhysicalFiles(%q, writer, space .. %q, %q) writer:Write[=[]]):format(
			name, space, option)
	else
		return ([[%s%s]=] __FileLoader__.OutputPhysicalFiles(%q, writer, space, %q) writer:Write[=[]]):format(
			ret, space, name, option)
	end
end

--[======================[
@{HtmlTable(self.Data)}
--]======================]
function parseHtmlHelper(ret, space, name, param)
	if ret == "@" and space == "" then return end
	param = param:sub(2, -2):gsub("^%s+", ""):gsub("%s+$", "")

	if param == "" then param = nil end

	if ret == "" then
		lhtmlLoader.SpaceHandled = true
		return ([[self:Render_%s(writer, space .. %q%s) writer:Write[=[]]):format(
			name,  space, param and ", " .. param or "")
	else
		return ([[%s%s]=] self:Render_%s(writer, space%s) writer:Write[=[]]):format(
			ret, space,	name, param and ", " .. param or "")
	end
end