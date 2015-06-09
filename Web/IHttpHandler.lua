--=============================
-- IHttpHandler
--
-- Author : Kurapica
-- Create Date : 2015/05/26
--=============================

_ENV = Module "System.Web.IHttpHandler" "1.0.0"

namespace "System.Web"

interface "IHttpHandler" {
	IHttpContext,

	ProcessRequest = function (self) end,
}
