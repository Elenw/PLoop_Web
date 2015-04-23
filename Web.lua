--===================================
-- System.Web
--
-- Author : Kurapica
-- Create Date : 2015/04/19
-- Change Log :
--===================================

_ENV = Module "System.Web" "1.0.0"

import "System"
namespace "System.Web"

Log = Logger("System_Web_Logger")

Log.TimeFormat = "%X"
Trace = Log:SetPrefix(1, "[System.Web][Trace]", true)
Debug = Log:SetPrefix(2, "[System.Web][Debug]", true)
Info = Log:SetPrefix(3, "[System.Web][Info]", true)
Warn = Log:SetPrefix(4, "[System.Web][Warn]", true)
Error = Log:SetPrefix(5, "[System.Web][Error]", true)
Fatal = Log:SetPrefix(6, "[System.Web][Fatal]", true)
Log.LogLevel = 3


--=============================
-- Interface
--=============================
__Final__()
interface "WebSettings" (function(_ENV)
	enum "LogLevel" {
		Trace = 1,
		Debug = 2,
		Info = 3,
		Warn = 4,
		Error = 5,
		Fatal = 6,
	}

	__Arguments__{ LogLevel }
	function SetLogLevel(lvl)
		Log.LogLevel = lvl
	end

	__Arguments__{ Function, LogLevel + nil }
	function AddLogHandler(handler, loglevel)
		Log:AddHandler(handler, loglevel)
	end
end)

interface "IWriter" {
	Closed = Boolean,

	Write = function(self, text) end,
	Flush = function(self) end,
	Close = function(self) end,
	Dispose = function(self) return not self.Closed and self:Close() end,
}

interface "IPage" {
	OnLoad = function(self) end,
	Render = function(self, writer) end,
}

interface "IFileLoader" {
	LoadFile = function(self, path, target) end,
}

--=============================
-- Attribtue
--=============================
__AttributeUsage__{AttributeTarget = AttributeTargets.Class, Inherited = false, RunOnce = true}
class "__FileLoader__" (function(_ENV)
	inherit "__Attribute__"

	_LuaLoader = nil
	_SuffixFileMap = {}
	_LoadedPathMap = {}

	__Static__() function LoadVirtualFiles(path)

	end

	__Static__() function LoadPhysicalFiles(path)
		Debug("LoadPhysicalFiles from %s", path)
		local target = _LoadedPathMap[path]

		if target == nil then
			if _LuaLoader then
				target = _LuaLoader():LoadFile(path .. ".lua")
			end

			for suffix, loader in pairs(_SuffixFileMap) do
				target = loader():LoadFile(path .. "." .. suffix)
			end

			_LoadedPathMap[path] = target-- or false
		end

		return target
	end

	__Static__() function OutputPhysicalFiles(path, writer, space, default)
		local target = LoadPhysicalFiles(path)

		if Reflector.IsClass(target) then
			local obj = target()
			obj:OnLoad()
			obj:Render(writer, space)
			obj:Dispose()
		else
			writer:Write(default)
		end
		writer:Flush()
	end

	property "Suffix" { Type = String }

	function ApplyAttribute(self, target)
		local suffix = self.Suffix and self.Suffix:lower()
		if suffix then
			if suffix == "lua" then
				_LuaLoader = target
			else
				_SuffixFileMap[suffix] = target
			end
			class (target) { IFileLoader }
		end
	end

	__Arguments__{ String }
	function __FileLoader__(self, name)
		Super(self)
		self.Suffix = name
	end
end)
