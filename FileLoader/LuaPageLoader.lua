--=============================
-- LuaPageLoader
--
-- Author : Kurapica
-- Create Date : 2015/05/10
--=============================
_ENV = Module "System.Web.LuaPageLoader" "1.1.0"

namespace "System.Web"

__FileLoader__"luap"
class "LuaPageLoader" {
	IFileLoader,

	LoadFile = function (self, path, target)
		local discardIndent = Web.DiscardIndent
		local name = target and Reflector.GetNameSpaceName(target) or path:match("([_%w]+)%.%w+$")

		local f = fopen(path, "r")

		if f then
			SetLhtmlLoader(self)

			self.Definition = { }

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
				self.TargetName = name

				-- Generate MasterPage property
				if self.MasterPage then
					tinsert(self.LuaCode, [[System.__Static__() property "MasterPage" { Type = -System.Web.MasterPage } ]])
				end

				if Reflector.IsSuperClass(target, MasterPage) then
					self.IsMasterPage = true
				end

				local main = {}

				while line do
					line = line:gsub("%s+$", "")

					if line ~= "" then
						if discardIndent then
							line = line:gsub("^%s+", "")
						end

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
					matched = 0
				end

				-- Generate EmbedPages property
				if self.EmbedPages and next(self.EmbedPages) then
					tinsert(self.LuaCode, [[System.__Static__() property "EmbedPages" { Type = System.Table } ]])
				end

				-- Generate the Main Html Page
				if Reflector.IsClass(target) then
					if Reflector.IsSuperClass(target, MasterPage) then
						if Reflector.GetSuperClass(target) == MasterPage then
							-- Only the root MasterPage has Render method
							local codes = self.LuaCode
							tinsert(codes, [[function Render(self, writer, indent) indent = indent or ""]])
							for _, line in ipairs(main) do tinsert(codes, line) end

							if #main > 0 then
								line = tremove(codes)
								if Web.UseWriterObject then
									line = line:gsub(([[writer:Write%%(%q%%)$]]):format(Web.LineBreak), "")
								else
									line = line:gsub(([[writer%%(%q%%)$]]):format(Web.LineBreak), "")
								end
								tinsert(codes, line)
							end

							tinsert(codes, "end")
						end
					else
						local codes = self.LuaCode
						tinsert(codes, [[function Render(self, writer, indent) indent = indent or ""]])

						tinsert(codes, [[Super.Render(self, writer, indent)]])

						if self.MasterPage then
							tinsert(codes, ([[local masterPage = %s.MasterPage()]]):format(self.TargetName))
							tinsert(codes, [[masterPage.HtmlPage = self]])
							tinsert(codes, [[masterPage:Output(indent)]])
						else
							for _, line in ipairs(main) do tinsert(codes, line) end

							if #main > 0 then
								line = tremove(codes)
								if Web.UseWriterObject then
									line = line:gsub(([[writer:Write%%(%q%%)$]]):format(Web.LineBreak), "")
								else
									line = line:gsub(([[writer%%(%q%%)$]]):format(Web.LineBreak), "")
								end
								tinsert(codes, line)
							end
						end

						tinsert(codes, "end")
					end
				end

				local define = tconcat(self.LuaCode, Web.LineBreak)

				if discardIndent then
					if Web.UseWriterObject then
						define = define:gsub("writer:Write%(indent%)", "")
					else
						define = define:gsub("writer%(indent%)", "")
					end
				end

				Debug("Generate definition for %s :", name)
				Debug("%s%s", Web.LineBreak, define)

				-- Recode the target class
				if Reflector.IsClass(target) then
					class (target) ( define )
				else
					interface (target) ( define )
				end

				-- Set EmbedPages
				if self.EmbedPages and next(self.EmbedPages) then
					target.EmbedPages = self.EmbedPages
				end

				-- Set MasterPage
				if self.MasterPage then
					target.MasterPage = self.MasterPage
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
				assert(not lhtmlLoader.Abstract, ("%s - the page is an abstract page, can't use inherit."):format(header))

				if Reflector.IsClass(v) then
					tinsert(lhtmlLoader.Definition, v)
				elseif type(v) == "string" then
					local cls = not v:match(Web.DirSeperator) and Reflector.GetNameSpaceForName(v)
					if Reflector.IsClass(cls) then
						tinsert(lhtmlLoader.Definition, cls)
					else
						local loader = lhtmlLoader
						local cls = __FileLoader__.LoadHandlerFromUrl(loader.Root, PathHelper.GetPathFromRelativePath(loader.Path, v))
						lhtmlLoader = loader
						if Reflector.IsClass(cls) then
							tinsert(lhtmlLoader.Definition, cls)
						else
							error(("%s - the super page file can't be found."):format(header))
						end
					end
				else
					error(("%s - inherit format error."):format(header))
				end
			elseif k == "extend" then
				if type(v) == "string" then
					for p in v:gmatch("[^%s,]+") do
						local itf = not p:match(Web.DirSeperator) and Reflector.GetNameSpaceForName(p)
						if Reflector.IsInterface(itf) then
							tinsert(lhtmlLoader.Definition, itf)
						else
							local loader = lhtmlLoader
							itf = __FileLoader__.LoadHandlerFromUrl(loader.Root, PathHelper.GetPathFromRelativePath(loader.Path, p))
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
			elseif k == "masterpage" and v then
				if Reflector.IsClass(v) then
					if Reflector.IsSuperClass(v, MasterPage) then
						lhtmlLoader.MasterPage = v
					else
						error(("%s - masterpage's value must be a System.Web.MasterPage class."):format(header))
					end
				elseif type(v) == "string" then
					local cls = not v:match(Web.DirSeperator) and Reflector.GetNameSpaceForName(v)
					if Reflector.IsClass(cls) then
						if Reflector.IsSuperClass(cls, MasterPage) then
							lhtmlLoader.MasterPage = cls
						else
							error(("%s - masterpage's value must be a System.Web.MasterPage class."):format(header))
						end
					else
						local loader = lhtmlLoader
						local cls = __FileLoader__.LoadHandlerFromUrl(loader.Root, PathHelper.GetPathFromRelativePath(loader.Path, v))
						lhtmlLoader = loader
						if Reflector.IsClass(cls) then
							if Reflector.IsSuperClass(cls, MasterPage) then
								lhtmlLoader.MasterPage = cls
							else
								error(("%s - masterpage's value must be a System.Web.MasterPage class."):format(header))
							end
						else
							error(("%s - the master page can't be found."):format(header))
						end
					end
				else
					error(("%s - masterpage format error."):format(header))
				end
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

	Trace("[LuaPageLoader][parsePageLine] << %s", line)

	lhtmlLoader.SpaceHandled = false

	-- Parse lua code
	newline = line:gsub("^%s*@>(.*)$", parseLine)
	if newline ~= line then
		Trace("[LuaPageLoader][parsePageLine] << %s", newline)
		return newline
	end
	newline = line:gsub("^%s*@%s*(%w+)(.*)$", parseLineWithKeyWord)
	if newline ~= line then
		Trace("[LuaPageLoader][parsePageLine] << %s", newline)
		return newline
	end

	-- Parse print code
	line = line:gsub("(%S?)@%s*(%b())", parsePrintParen)
	line = line:gsub("(%S?)@%s*([_%w]+.+)", parsePrint)

	-- Parse html helper
	line = line:gsub("(%S?)(%s*)@%s*{%s*([_%w]+)%s*(%b())%s*}", parseHtmlHelper)

	-- Parse web part
	line = line:gsub("(%S?)(%s*)@%s*{%s*([_%w]+)%s*(.-)%s*}", parseWebPart)

	-- Parse embed page
	line = line:gsub("(%S?)(%s*)@%s*(%b[])", parseEmbedPage)

	-- Format code
	line = line:gsub("@@", "@")

	if not lhtmlLoader.SpaceHandled then
		if Web.UseWriterObject then
			line = [[writer:Write(indent) writer:Write[=[]] .. line
		else
			line = [[writer(indent) writer[=[]] .. line
		end
	end

	if Web.UseWriterObject then
		if Web.DiscardLineBreak then
			line = line .. ([[]=] ]])
		else
			line = line .. ([[]=] writer:Write(%q)]]):format(Web.LineBreak)
		end
		line = line:gsub("%s*writer:Write%[=%[%]=%]%s*", " ")
	else
		if Web.DiscardLineBreak then
			line = line .. ([[]=] ]])
		else
			line = line .. ([[]=] writer(%q)]]):format(Web.LineBreak)
		end
		line = line:gsub("%s*writer%[=%[%]=%]%s*", " ")
	end

	Trace("[LuaPageLoader][parsePageLine] >> %s", line)

	return line
end

--[======================[
@{
	-- global lua code block
}
--]======================]
function parseLuaCode()
	local codes = lhtmlLoader.LuaCode
	local prev

	for line in lhtmlLoader.Lines do
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
	local codes = lhtmlLoader.LuaCode
	local prev
	local lineCnt = 0
	local discardIndent = Web.DiscardIndent

	param = param:sub(2, -2)

	tinsert(codes, ([[function Render_%s(self, writer, indent, %s) indent = indent or ""]]):format(name, param))

	for line in lhtmlLoader.Lines do
		line = line:gsub("%s+$", "")
		if not prev then prev = "^" .. (line:match("^%s+") or "") end

		if line == "}" then
			if lineCnt > 0 then
				line = tremove(codes)

				if Web.UseWriterObject then
					line = line:gsub(([[writer:Write%%(%q%%)$]]):format(Web.LineBreak), "")
				else
					line = line:gsub(([[writer%%(%q%%)$]]):format(Web.LineBreak), "")
				end

				tinsert(codes, line)
			end
			tinsert(codes, "end")
			return
		end

		if discardIndent then
			line = line:gsub("^%s+", "")
		elseif prev then
			line = line:gsub(prev, "")
		end

		lineCnt = lineCnt + 1
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
	local codes = lhtmlLoader.LuaCode
	local prev
	local lineCnt = 0
	local discardIndent = Web.DiscardIndent

	tinsert(codes, ([[function Render_%s(self, writer, indent) indent = indent or ""]]):format(name))

	for line in lhtmlLoader.Lines do
		line = line:gsub("%s+$", "")
		if not prev then prev = "^" .. (line:match("^%s+") or "") end

		if line == "}" then
			if lineCnt > 0 then
				line = tremove(codes)

				if Web.UseWriterObject then
					line = line:gsub(([[writer:Write%%(%q%%)$]]):format(Web.LineBreak), "")
				else
					line = line:gsub(([[writer%%(%q%%)$]]):format(Web.LineBreak), "")
				end

				tinsert(codes, line)
			end
			tinsert(codes, "end")
			return
		end

		if discardIndent then
			line = line:gsub("^%s+", "")
		elseif prev then
			line = line:gsub(prev, "")
		end

		lineCnt = lineCnt + 1
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
		if Web.UseWriterObject then
			return ([[%s]=] writer:Write(tostring%s) writer:Write[=[]]):format(prev, printCode)
		else
			return ([[%s]=] writer(tostring%s) writer[=[]]):format(prev, printCode)
		end
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

		if Web.UseWriterObject then
			return ([[%s]=] writer:Write(%s) writer:Write[=[%s]]):format(prev, code, printCode)
		else
			return ([[%s]=] writer(%s) writer[=[%s]]):format(prev, code, printCode)
		end
	end
end

--[======================[
@{body this should be a body part}
--]======================]
function parseWebPart(ret, indent, name, option)
	if ret == "@" and indent == "" then return end
	if  ret == "" then
		lhtmlLoader.SpaceHandled = true

		if lhtmlLoader.IsMasterPage then
			if Web.UseWriterObject then
				return ([[self:RenderWebPart(%q, writer, indent .. %q, %q) writer:Write[=[]]):format(name, indent, option)
			else
				return ([[self:RenderWebPart(%q, writer, indent .. %q, %q) writer[=[]]):format(name, indent, option)
			end
		else
			if Web.UseWriterObject then
				return ([[if self.Render_%s then self:Render_%s(writer, indent .. %q) else writer:Write(indent) writer:Write(%q) end writer:Write[=[]]):format(
					name, name, indent, option)
			else
				return ([[if self.Render_%s then self:Render_%s(writer, indent .. %q) else writer(indent) writer(%q) end writer[=[]]):format(
					name, name, indent, option)
			end
		end
	else
		if lhtmlLoader.IsMasterPage then
			if Web.UseWriterObject then
				return ([[%s%s]=] self:RenderWebPart(%q, writer, "", %q) writer:Write[=[]]):format(ret, indent, name, option)
			else
				return ([[%s%s]=] self:RenderWebPart(%q, writer, "", %q) writer[=[]]):format(ret, indent, name, option)
			end
		else
			if Web.UseWriterObject then
				return ([[%s%s]=] if self.Render_%s then self:Render_%s(writer, "") else writer:Write(%q) end writer:Write[=[]]):format(
					ret, indent, name, name, option)
			else
				return ([[%s%s]=] if self.Render_%s then self:Render_%s(writer, "") else writer(%q) end writer[=[]]):format(
					ret, indent, name, name, option)
			end
		end
	end
end

--[======================[
@[url get web part from other pages]
@[share/login(self.Data) default messages]
@[share/login default messages]
--]======================]
function parseEmbedPage(ret, indent, content)
	if ret == "@" and indent == "" then return end

	content = content:sub(2, -2)

	local url, param, default = content:match("^%s*([^%s(]*)%s*(%b())%s*(.-)%s*$")
	if not url or url == "" then
		url, default = content:match("^%s*(%S*)%s*(.-)%s*$")
		param = "nil"
	else
		param = param:sub(2, -2):gsub("^%s*(.-)%s*$", "%1")
		if param == "" then param = "nil" end
	end

	local loader = lhtmlLoader
	local cls = __FileLoader__.LoadHandlerFromUrl(loader.Root, PathHelper.GetPathFromRelativePath(loader.Path, url))
	lhtmlLoader = loader
	if Reflector.IsClass(cls) then
		loader.EmbedPages = loader.EmbedPages or {}
		loader.EmbedPages[url] = cls
	else
		if Web.UseWriterObject then
			return ([[%s%s]=] writer:Write(%q) writer:Write[=[]]):format(
				ret, indent, default)
		else
			return ([[%s%s]=] writer(%q) writer[=[]]):format(
				ret, indent, default)
		end
	end

	if ret == "" then
		lhtmlLoader.SpaceHandled = true

		if Web.UseWriterObject then
			return ([[self:OutputWithOther(%s.EmbedPages[%q](%s), indent .. %q) writer:Write[=[]]):format(
				lhtmlLoader.TargetName, url, param, indent)
		else
			return ([[self:OutputWithOther(%s.EmbedPages[%q](%s), indent .. %q) writer[=[]]):format(
				lhtmlLoader.TargetName, url, param, indent)
		end
	else
		if Web.UseWriterObject then
			return ([[%s%s]=] self:OutputWithOther(%s.EmbedPages[%q](%s), "") writer:Write[=[]]):format(
				ret, indent, lhtmlLoader.TargetName, url, param)
		else
			return ([[%s%s]=] self:OutputWithOther(%s.EmbedPages[%q](%s), "") writer[=[]]):format(
				ret, indent, lhtmlLoader.TargetName, url, param)
		end
	end
end

--[======================[
@{HtmlTable(self.Data)}
--]======================]
function parseHtmlHelper(ret, indent, name, param)
	if ret == "@" and indent == "" then return end
	param = param:sub(2, -2):gsub("^%s+", ""):gsub("%s+$", "")

	if param == "" then param = nil end

	if ret == "" then
		lhtmlLoader.SpaceHandled = true

		if Web.UseWriterObject then
			return ([[self:Render_%s(writer, indent .. %q%s) writer:Write[=[]]):format(
				name, indent, param and ", " .. param or "")
		else
			return ([[self:Render_%s(writer, indent .. %q%s) writer[=[]]):format(
				name, indent, param and ", " .. param or "")
		end
	else
		if Web.UseWriterObject then
			return ([[%s%s]=] self:Render_%s(writer, ""%s) writer:Write[=[]]):format(
				ret, indent, name, param and ", " .. param or "")
		else
			return ([[%s%s]=] self:Render_%s(writer, ""%s) writer[=[]]):format(
				ret, indent, name, param and ", " .. param or "")
		end
	end
end