--===================================
-- System.Web
--
-- Author : Kurapica
-- Create Date : 2015/04/19
-- Change Log :
--===================================
_ENV = Module "System.Web" "0.1.0"

import "System"

Log = Logger("System.Web.Logger")

Log.TimeFormat = "%X"
Trace = Log:SetPrefix(1, "[System.Web][Trace]", true)
Debug = Log:SetPrefix(2, "[System.Web][Debug]", true)
Info = Log:SetPrefix(3, "[System.Web][Info]", true)
Warn = Log:SetPrefix(4, "[System.Web][Warn]", true)
Error = Log:SetPrefix(5, "[System.Web][Error]", true)
Fatal = Log:SetPrefix(6, "[System.Web][Fatal]", true)
Log.LogLevel = 3

--=============================
-- System.Web
--=============================
__NameSpace__ "System"
__Final__()
interface "Web" (function(_ENV)
	enum "LogLevel" {
		Trace = 1,
		Debug = 2,
		Info = 3,
		Warn = 4,
		Error = 5,
		Fatal = 6,
	}

	enum "HttpMethod" {
		"OPTIONS",
		"GET",
		"HEAD",
		"POST",
		"PUT",
		"DELETE",
		"TRACE",
		"CONNECT",
	}
	__Static__() property "LineBreak" { Type = String, Default = "\n" }
	__Static__() property "DebugMode" { Type = Boolean }
	__Static__() property "UseWriterObject" { Type = Boolean, Default = true }
	__Static__() property "DirSeperator" { Type = String, Default = "/"}

	__Arguments__{ LogLevel }
	function SetLogLevel(lvl)
		Log.LogLevel = lvl
	end

	__Arguments__{ Function, LogLevel + nil }
	function AddLogHandler(handler, loglevel)
		Log:AddHandler(handler, loglevel)
	end
end)

--=============================
-- System.Web.*
--=============================
namespace "System.Web"

--=============================
-- Interface
--=============================
__Cache__()
interface "IWriter" {
	Closed = Boolean,

	Write = function(self, text) end,
	Flush = function(self) end,
	Close = function(self) end,
	Dispose = function(self) return not self.Closed and self:Close() end,
}