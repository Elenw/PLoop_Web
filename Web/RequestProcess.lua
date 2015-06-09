--===================================
-- System.Web
--
-- Author : Kurapica
-- Create Date : 2015/05/26
-- Change Log :
--===================================
_ENV = Module "System.Web.ProcessRequest" "1.0.0"

namespace "System.Web"

-- __Arguments__{ HttpRequest, HttpResponse }
function Web.ProcessRequest(request, response)
	local path, option = PathMap.GetPathFromUrl(request.Url)
	local handlerCls = __FileLoader__.LoadHandlerFromUrl(request.Root, path)

	if Reflector.IsClass(handlerCls) and Reflector.IsExtendedInterface(handlerCls, IHttpHandler) then
		local handler = handlerCls(option)

		handler.Request = request
		handler.Response = response

		handler:ProcessRequest()

		if Web.UseWriterObject then
			response.Writer:Close()
		end

		return
	end

	-- @todo : 404
end