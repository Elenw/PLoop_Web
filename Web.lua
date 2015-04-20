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

--=============================
-- Interface
--=============================
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
