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
	LoadFile = function(self, path, cls) end,
}

--=============================
-- Attribtue
--=============================
__AttributeUsage__{AttributeTarget = AttributeTargets.Class, Inherited = false, RunOnce = true}
class "__FileLoader__" (function(_ENV)
	inherit "__Attribute__"

	_SuffixFileMap = {}

	property "Suffix" { Type = String }

	__Static__() function GetFileLoader(suffix)
		return _SuffixFileMap[type(suffix) == "string" and suffix:lower()]
	end

	function ApplyAttribute(self, target)
		local suffix = self.Suffix and self.Suffix:lower()
		if suffix then
			_SuffixFileMap[suffix] = target
			class (target) { IFileLoader }
		end
	end

	__Arguments__{ String }
	function __FileLoader__(self, name)
		Super(self)
		self.Suffix = name
	end
end)
