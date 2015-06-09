--=============================
-- MasterPage
--
-- Author : Kurapica
-- Create Date : 2015/06/07
--=============================

_ENV = Module "System.Web.MasterPage" "1.0.0"

namespace "System.Web"

class "MasterPage" {
	IHtmlOutput,

	HtmlPage = { Type = IHtmlOutput, Handler = function(self, value) self:CopyContext(value) end },

	OnLoad = function (self) end,

	Render = function (self, writer, indent) end,

	RenderWebPart = function (self, name, writer, indent, option)
		name = "Render_" .. name

		local page = self.HtmlPage
		local method
		if page then
			method = page[name]
			if method then
				return method(page, writer, indent)
			end
		end

		method = self[name]
		if method then
			return self[name](self, writer, indent)
		end

		if Web.UseWriterObject then
			writer:Write(indent)
			writer:Write(option)
		else
			writer(indent)
			writer(option)
		end
	end,

	Output = function (self, indent)
		self:OnLoad()
		self:Render(self.Response.Writer, indent)
	end,
}