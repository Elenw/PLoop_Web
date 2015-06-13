require "PLoop_Web"

import "System"
import "System.Web"

--=============================
-- PLoop_Web Settings
--=============================
Web.DebugMode = true

Web.SetLogLevel(Web.LogLevel.Info)

Web.AddLogHandler(function (text)
	ngx.log(ngx.ERR, text)
end)

function ngxLua_ProcessRequest(urlConvertor)
	Web.ProcessRequest(NgxLua_HttpRequest(), NgxLua_HttpResponse(), urlConvertor)
end

function mvcUrlConvertor(url)
	local controller, action, id = url:match("^/(%w+)/(%w+)/(%d+)$")

	if controller and action and id then
		return ("/controller/%sController"):format(controller), { Action = action, Id = id }
	end
end

--=============================
-- !!! Dont't touch unless you know it !!!
-- PLoop_Web Interface for ngx_lua
--=============================

--=============================
-- Cookies For ngx_lua
--=============================
Web.UseWriterObject = false

class "NginxLua_CookiesReader" {
	__index = function (self, key)
		if type(key) == "string" then
			local value = ngx.var["cookie_" .. key]
			if value ~= nil then
				rawset(self, key, value)
			end
			return value
		end
	end
}

class "NginxLua_CookiesWriter" {
}

--=============================
-- HttpRequest For ngx_lua
--=============================
class "NgxLua_HttpRequest" (function (_ENV)
	inherit "HttpRequest"

	property "ContentLength" { Set = false, Default = function() return ngx.var.content_length end }

	property "ContentType" { Set = false, Default = function () return ngx.var.content_type end }

	property "Cookies" { Set = false, Default = function() return NginxLua_CookiesReader() end }

	property "Form" { Set = false, Default = function() ngx.req.read_body() return ngx.req.get_post_args() or {} end }

	property "HttpMethod" { Set = false, Default = function() return HttpMethod[ngx.var.request_method] end }

	property "IsSecureConnection" { Set = false, Default = function() return ngx.var.https == "on" end }

	property "QueryString" { Set = false, Default = function() return ngx.req.get_uri_args() or {} end }

	property "RawUrl" { Set = false, Default = function () return ngx.var.request_uri end }

	property "Root" { Set = false, Default = function() return ngx.var.realpath_root end }

	property "Url" { Set = false, Default = function () return ngx.var.uri end }
end)

--=============================
-- HttpResponse For ngx_lua
--=============================
class "NgxLua_HttpResponse" (function (_ENV)
	inherit "HttpResponse"

	__Handler__(function (self, value) ngx.header.content_type = value end)
	property "ContentType" { Type = String }

	property "Writer" { Set = false , Default = function () return ngx.print end }

	__Handler__(function (self, value) ngx.status = value end)
	property "StatusCode" { Type = HTTP_STATUS }
end)