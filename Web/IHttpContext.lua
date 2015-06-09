--=============================
-- IHttpContext
--
-- Author : Kurapica
-- Create Date : 2015/06/08
--=============================

_ENV = Module "System.Web.IHttpContext" "1.0.0"

namespace "System.Web"

interface "IHttpContext" {
	Request = { Type = HttpRequest },
	Response = { Type = HttpResponse },

	CopyContext = function (self, src)
		self.Request = src.Request
		self.Response = src.Response
	end,
}