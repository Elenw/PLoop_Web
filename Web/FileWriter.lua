--=============================
-- FileWriter
--
-- Author : Kurapica
-- Create Date : 2015/04/19
--=============================
_ENV = Module "System.Web.FileWriter" "1.0.0"

fopen = io.open

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

class "FileWriter" (function(_ENV)
	extend "IWriter"

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