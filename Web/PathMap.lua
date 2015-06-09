--===================================
-- System.Web
--
-- Author : Kurapica
-- Create Date : 2015/05/26
-- Change Log :
--===================================
_ENV = Module "System.Web.PathMap" "1.0.0"

tinsert = table.insert

__Final__()
interface "PathMap" (function (_ENV)
	_VirtualPathMap = {}

	function CombineRootPath(root, path)
		local dir = Web.DirSeperator

		-- Remove the suffix
		path = path:gsub("%.%w*$", "")

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

	function GetPathFromUrl(url)
		for _, map in ipairs(_VirtualPathMap) do
			local urlFormat = map.UrlFormat
			local path, option

			if urlFormat then
				path, option = map.Mapper(url, url:match(urlFormat))
			else
				path, option = map.Mapper(url)
			end

			if path then
				return path, option
			end
		end
	end

	function GetPathFromRelativePath(path, relativePath)
		local dir = Web.DirSeperator

		if relativePath:sub(1, 1) == dir then
			return relativePath
		else
			return path:gsub(("[^%s]*$"):format(dir), "") .. relativePath
		end
	end

	__Arguments__{ Function, String + nil }
	function RegisterVirtualPathMap(mapper, urlFormat)
		tinsert(_VirtualPathMap, 1, { Mapper = mapper, UrlFormat = urlFormat })
	end

	function DIRECT_PATHMAP(path)
		return path
	end
end)

-- Default
PathMap.RegisterVirtualPathMap(PathMap.DIRECT_PATHMAP)