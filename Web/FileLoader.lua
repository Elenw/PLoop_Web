--=============================
-- FileLoader
--
-- Author : Kurapica
-- Create Date : 2015/05/26
--=============================

_ENV = Module "System.Web.FileLoader" "1.0.0"

namespace "System.Web"

interface "IFileLoader" {
	Root = String,
	Path = String,

	LoadFile = function(self, path, target) end,
}

__AttributeUsage__{AttributeTarget = AttributeTargets.Class, Inherited = false, RunOnce = true}
class "__FileLoader__" (function(_ENV)
	inherit "__Attribute__"

	import "System.Web.PathMap"

	_LuaLoader = nil
	_SuffixFileMap = {}
	_LoadedPathMap = {}

	__Static__() function LoadHandlerFromUrl(root, path)
		local phyPath = CombineRootPath(root, path)
		local target = _LoadedPathMap[phyPath]

		if target == nil then
			-- Lua Loader
			if _LuaLoader then
				local loader = _LuaLoader()
				loader.Root = root
				loader.Path = path

				target = loader:LoadFile(phyPath .. ".lua")
			end

			for suffix, loader in pairs(_SuffixFileMap) do
				loader = loader()
				loader.Root = root
				loader.Path = path

				target = loader:LoadFile(phyPath .. "." .. suffix, target)
			end

			if not Web.DebugMode then
				_LoadedPathMap[phyPath] = target
			end
		end

		return target
	end

	property "Suffix" { Type = String }

	function ApplyAttribute(self, target)
		assert(Reflector.IsExtendedInterface(target, IFileLoader), "The class must extend System.Web.IFileLoader.")

		local suffix = self.Suffix and self.Suffix:lower()
		if suffix then
			if suffix == "lua" then
				_LuaLoader = target
			else
				_SuffixFileMap[suffix] = target
			end
		end
	end

	__Arguments__{ String }
	function __FileLoader__(self, name)
		Super(self)
		self.Suffix = name
	end
end)