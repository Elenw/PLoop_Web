--=============================
-- IHtmlOutput
--
-- Author : Kurapica
-- Create Date : 2015/06/07
--=============================

_ENV = Module "System.Web.IHtmlOutput" "1.0.0"

namespace "System.Web"

interface "IHtmlOutput" {
	IHttpContext,

	Output = function (self, indent) end,

	OutputWithOther = function (self, handler, indent)
		handler:CopyContext(self)
		handler:Output(indent)
	end,
}