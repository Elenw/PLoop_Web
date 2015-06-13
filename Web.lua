--===================================
-- System.Web
--
-- Author : Kurapica
-- Create Date : 2015/04/19
-- Change Log :
--===================================
_ENV = Module "System.Web" "0.1.0"

import "System"

Log = Logger("System.Web.Logger")

Log.TimeFormat = "%X"
Trace = Log:SetPrefix(1, "[System.Web][Trace]", true)
Debug = Log:SetPrefix(2, "[System.Web][Debug]", true)
Info = Log:SetPrefix(3, "[System.Web][Info]", true)
Warn = Log:SetPrefix(4, "[System.Web][Warn]", true)
Error = Log:SetPrefix(5, "[System.Web][Error]", true)
Fatal = Log:SetPrefix(6, "[System.Web][Fatal]", true)
Log.LogLevel = 3

--=============================
-- System.Web
--=============================
__NameSpace__ "System"
__Final__()
interface "Web" (function(_ENV)

	__Cache__()
	interface "IWriter" {
		Closed = Boolean,

		Write = function(self, text) end,
		Flush = function(self) end,
		Close = function(self) end,
		Dispose = function(self) return not self.Closed and self:Close() end,
	}

	enum "LogLevel" {
		Trace = 1,
		Debug = 2,
		Info = 3,
		Warn = 4,
		Error = 5,
		Fatal = 6,
	}

	__Default__"GET"
	enum "HttpMethod" {
		"OPTIONS",
		"GET",
		"HEAD",
		"POST",
		"PUT",
		"DELETE",
		"TRACE",
		"CONNECT",
	}

	enum "HTTP_STATUS" {
		CONTINUE = 100,				--The request can be continued.
		SWITCH_PROTOCOLS = 101,		--The server has switched protocols in an upgrade header.
		OK = 200,					--The request completed successfully.
		CREATED = 201,				--The request has been fulfilled and resulted in the creation of a new resource.
		ACCEPTED = 202,				--The request has been accepted for processing, but the processing has not been completed.
		PARTIAL = 203,				--The returned meta information in the entity-header is not the definitive set available from the originating server.
		NO_CONTENT = 204,			--The server has fulfilled the request, but there is no new information to send back.
		RESET_CONTENT = 205,		--The request has been completed, and the client program should reset the document view that caused the request to be sent to allow the user to easily initiate another input action.
		PARTIAL_CONTENT = 206,		--The server has fulfilled the partial GET request for the resource.
		WEBDAV_MULTI_STATUS = 207,	--This indicates multiple status codes for a single response. The response body contains Extensible Markup Language (XML) that describes the status codes. For more information, see HTTP Extensions for Distributed Authoring.
		AMBIGUOUS = 300,			--The requested resource is available at one or more locations.
		MOVED = 301,				--The requested resource has been assigned to a new permanent Uniform Resource Identifier (URI), and any future references to this resource should be done using one of the returned URIs.
		REDIRECT = 302,				--The requested resource resides temporarily under a different URI.
		REDIRECT_METHOD = 303,		--The response to the request can be found under a different URI and should be retrieved using a GET HTTP verb on that resource.
		NOT_MODIFIED = 304,			--The requested resource has not been modified.
		USE_PROXY = 305,			--The requested resource must be accessed through the proxy given by the location field.
		REDIRECT_KEEP_VERB = 307,	--The redirected request keeps the same HTTP verb. HTTP/1.1 behavior.
		BAD_REQUEST = 400,			--The request could not be processed by the server due to invalid syntax.
		DENIED = 401,				--The requested resource requires user authentication.
		PAYMENT_REQ = 402,			--Not implemented in the HTTP protocol.
		FORBIDDEN = 403,			--The server understood the request, but cannot fulfill it.
		NOT_FOUND = 404,			--The server has not found anything that matches the requested URI.
		BAD_METHOD = 405,			--The HTTP verb used is not allowed.
		NONE_ACCEPTABLE = 406,		--No responses acceptable to the client were found.
		PROXY_AUTH_REQ = 407,		--Proxy authentication required.
		REQUEST_TIMEOUT = 408,		--The server timed out waiting for the request.
		CONFLICT = 409,				--The request could not be completed due to a conflict with the current state of the resource. The user should resubmit with more information.
		GONE = 410,					--The requested resource is no longer available at the server, and no forwarding address is known.
		LENGTH_REQUIRED = 411,		--The server cannot accept the request without a defined content length.
		PRECOND_FAILED = 412,		--The precondition given in one or more of the request header fields evaluated to false when it was tested on the server.
		REQUEST_TOO_LARGE = 413,	--The server cannot process the request because the request entity is larger than the server is able to process.
		URI_TOO_LONG = 414,			--The server cannot service the request because the request URI is longer than the server can interpret.
		UNSUPPORTED_MEDIA = 415,	--The server cannot service the request because the entity of the request is in a format not supported by the requested resource for the requested method.
		RETRY_WITH = 449,			--The request should be retried after doing the appropriate action.
		SERVER_ERROR = 500,			--The server encountered an unexpected condition that prevented it from fulfilling the request.
		NOT_SUPPORTED = 501,		--The server does not support the functionality required to fulfill the request.
		BAD_GATEWAY = 502,			--The server, while acting as a gateway or proxy, received an invalid response from the upstream server it accessed in attempting to fulfill the request.
		SERVICE_UNAVAIL = 503,		--The service is temporarily overloaded.
		GATEWAY_TIMEOUT = 504,		--The request was timed out waiting for a gateway.
		VERSION_NOT_SUP = 505,		--The server does not support the HTTP protocol version that was used in the request message.
	}

	__Static__() property "DebugMode" { Type = Boolean }
	__Static__() property "UseWriterObject" { Type = Boolean, Default = true }
	__Static__() property "DiscardIndent" { Type = Boolean }
	__Static__() property "DiscardLineBreak" { Type = Boolean }

	__Static__() property "LineBreak" { Type = String, Default = "\n" }
	__Static__() property "DirSeperator" { Type = String, Default = "/"}

	__Arguments__{ LogLevel }
	function SetLogLevel(lvl)
		Log.LogLevel = lvl
	end

	__Arguments__{ Function, LogLevel + nil }
	function AddLogHandler(handler, loglevel)
		Log:AddHandler(handler, loglevel)
	end
end)