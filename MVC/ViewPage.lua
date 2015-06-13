--=============================
-- ViewPage
--
-- Author : Kurapica
-- Create Date : 2015/06/10
--=============================

_ENV = Module "System.Web.MVC.ViewPage" "1.0.0"

namespace "System.Web.MVC"

class "ViewPage" {
	IHtmlOutput,

	OnLoad = function (self) end,

	Render = function (self, writer, indent) end,

	Output = function (self, indent)
		self:OnLoad()
		self:Render(self.Response.Writer, indent)
	end,
}