--=============================
-- Controller
--
-- Author : Kurapica
-- Create Date : 2015/06/10
--=============================

_ENV = Module "System.Web.MVC.Controller" "1.0.0"

namespace "System.Web.MVC"

import "System.Web"

_HttpMethodMap = setmetatable({}, { __mode = "k" })

class "Controller" {
	IHttpHandler,

	-- Property
	Action = String,

	-- Method
	Text = function (self, text)
		local res = self.Response

		text = tostring(text)

		res.ContentType = "text/plain"

		if Web.UseWriterObject then
			res.Writer:Write(text)
		else
			res.Writer(text)
		end
	end,

	-- ProcessRequest
	ProcessRequest = function (self)
		local map = _HttpMethodMap[getmetatable(self)]

		if map then
			map = map[self.Request.HttpMethod]
			if map then
				map = map[self.Action:lower()]
				if map then
					return self[map](self)
				end
			end
		end

		response.StatusCode = HTTP_STATUS.NOT_FOUND
	end,
}

__AttributeUsage__{AttributeTarget = AttributeTargets.Method, Inherited = false, RunOnce = true}
__Unique__()
class "__HttpMethod__" (function(_ENV)
	inherit "__Attribute__"

	property "Method" { Type = HttpMethod + nil, Default = "GET" }

	property "Action" { Type = String + nil }

	function ApplyAttribute(self, target, targetType, owner, name)
		local method = self.Method
		local action = self.Action

		if not Reflector.IsSuperClass(owner, Controller) then return end

		if not action or #action == 0 then action = name end

		local map

		_HttpMethodMap[owner] = _HttpMethodMap[owner] or {}

		map = _HttpMethodMap[owner]

		map[method] = map[method] or {}

		map = map[method]

		map[action:lower()] = name
	end

	__Arguments__{ HttpMethod + nil, String + nil }
	function __HttpMethod__(self, method, action)
		Super(self)

		self.Method = method
		self.Action = action
	end

	function Dispose(self)
		self.Action = nil
		self.Method = nil
	end
end)
