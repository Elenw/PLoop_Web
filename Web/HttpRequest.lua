--=============================
-- HttpRequest
--
-- Author : Kurapica
-- Create Date : 2015/05/26
--=============================

_ENV = Module "System.Web.HttpRequest" "1.0.0"

namespace "System.Web"

class "HttpRequest" (function (_ENV)
	__Doc__ "Specifies the length, in bytes, of content sent by the client."
	property "ContentLength" { }

	__Doc__ "Gets the MIME content type of the incoming request."
	property "ContentType" { }

	__Doc__ "Gets a collection of cookies sent by the client."
	property "Cookies" { }

	__Doc__ "Gets a collection of form variables."
	property "Form" { }

	__Doc__ "Gets the HTTP data transfer method (such as GET, POST, or HEAD) used by the client."
	property "HttpMethod" { }

	__Doc__ "Gets a value indicating whether the HTTP connection uses secure sockets (that is, HTTPS)."
	property "IsSecureConnection" { }

	__Doc__ "Gets the collection of HTTP query string variables."
	property "QueryString" { }

	__Doc__ "Gets the raw URL of the current request."
	property "RawUrl" { }

	__Doc__ "Get the root path of the query document."
	property "Root" { }

	__Doc__ "Gets information about the URL of the current request."
	property "Url" { }
end)