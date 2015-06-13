--===================================
-- System.Web
--
-- Author : Kurapica
-- Create Date : 2015/05/26
-- Change Log :
--===================================
_ENV = Module "System.Web.ProcessRequest" "1.0.0"

namespace "System.Web"

-- __Arguments__{ HttpRequest, HttpResponse, Function + nil }
function Web.ProcessRequest(request, response, urlConvertor)
	local handler

	if urlConvertor then
		handler = GetHttpHandler(request.Root, urlConvertor(request.Url))
	else
		handler = GetHttpHandler(request.Root, request.Url)
	end

	if handler then
		response.StatusCode = HTTP_STATUS.OK

		handler.Request = request
		handler.Response = response

		handler:ProcessRequest()

		if Web.UseWriterObject then
			response.Writer:Close()
		end

		return
	end

	-- 404
	response.StatusCode = HTTP_STATUS.NOT_FOUND
end

function GetHttpHandler(root, path, ...)
	if path then
		local handlerCls = __FileLoader__.LoadHandlerFromUrl(root, path)

		if Reflector.IsClass(handlerCls) and Reflector.IsExtendedInterface(handlerCls, IHttpHandler) then
			return handlerCls(...)
		end
	end
end