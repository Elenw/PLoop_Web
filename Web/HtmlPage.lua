--=============================
-- HtmlPage
--
-- Author : Kurapica
-- Create Date : 2015/06/01
--=============================

_ENV = Module "System.Web.HtmlPage" "1.0.0"

namespace "System.Web"

class "HtmlPage" {
	IHttpHandler,
	IHtmlOutput,

	OnLoad = function (self) end,

	Render = function (self, writer, indent) end,

	Output = function (self, indent)
		self:OnLoad()
		self:Render(self.Response.Writer, indent)
	end,

	ProcessRequest = function (self)
		self.Response.ContentType = "text/html"

		self:Output("")
	end,
}