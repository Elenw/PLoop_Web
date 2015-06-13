--=============================
-- HttpResponse
--
-- Author : Kurapica
-- Create Date : 2015/05/26
--=============================

_ENV = Module "System.Web.HttpResponse" "1.0.0"

namespace "System.Web"

class "HttpResponse" (function (_ENV)
	__Doc__ "Gets or sets the HTTP MIME type of the output stream."
	property "ContentType" { }

	__Doc__ "Gets or sets the response writer."
	property "Writer" { Type = IWriter + Function }

	__Doc__ "Gets or sets the HTTP status code of the output returned to the client."
	property "StatusCode" { Type = Integer, Default = System.Any }
end)