require "PLoop_Web"

import "System"
import "System.Web"

fopen = io.open
tinsert = table.insert
tconcat = table.concat

Web.DiscardIndent = false
Web.DiscardLineBreak = false

Web.SetLogLevel(Web.LogLevel.Debug)
Web.AddLogHandler(print)

class "CacheWriter" { IWriter,
	Write = function(self, text) if text then tinsert(self, text) end end,
	Close = function(self) print(tconcat(self, "")) end,
}

class "FileWriter" (function(_ENV)
	extend "IWriter"

	__Default__"w"
	enum "FileWriteMode" {
		Write = "w",
		Append = "a",
		WritePlus = "w+",
		AppendPlus = "a+",
		WriteBinary = "wb",
		AppendBinary = "ab",
		WritePlusBinary = "w+b",
		AppendPlusBinary = "a+b",
	}

	-- Property
	property "File" { Type = Userdata + nil }
	property "Closed" { Get = function (self)
		return (not self.File or tostring(self.File):match("close")) and true or false
	end}

	-- Method
	function Write(self, text)
		if text ~= nil then self.File:write(text) end
	end

	function Flush(self)
		self.File:flush()
	end

	function Close(self)
		self.File:close()
	end

	-- Constructor
	__Arguments__{ Userdata + String, FileWriteMode + nil }
	function FileWriter(self, file, mode)
		if type(file) == "userdata" and tostring(file):match("^file") then
			self.File = file
		elseif type(file) == "string" then
			self.File = fopen(file, mode)
		end

		assert(self.File , "No file can be written.")
	end
end)

function main(writer)
	local st = os.clock()

	Web.ProcessRequest(
		HttpRequest {
			Root = "/Users/wangxianghui/developer/ploop_web/example/lua",
			Url = "/index.lua",
		},
		HttpResponse { Writer = writer }
	)

	print("Cost", os.clock() - st)
end

main( FileWriter("output.html") )
main( CacheWriter() )
