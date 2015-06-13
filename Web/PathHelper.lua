--===================================
-- System.Web
--
-- Author : Kurapica
-- Create Date : 2015/05/26
-- Change Log :
--===================================
_ENV = Module "System.Web.PathHelper" "1.0.0"

namespace "System.Web"

__Final__()
interface "PathHelper" (function (_ENV)

	function CombineRootPath(root, path)
		local dir = Web.DirSeperator

		local rootDir = root:sub(-1) == dir
		local pathDir = path:sub(1, 1) == dir

		if rootDir and pathDir then
			path = root:sub(1, -2) .. path
		elseif rootDir or pathDir then
			path = root .. path
		else
			path = root .. dir .. path
		end

		return path:lower()
	end

	function GetPathFromRelativePath(path, relativePath)
		local dir = Web.DirSeperator

		if relativePath:sub(1, 1) == dir then
			return relativePath
		else
			return path:gsub(("[^%s]*$"):format(dir), "") .. relativePath
		end
	end
end)
