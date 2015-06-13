import "System.Web"
import "System.Web.MVC"

class "HomeController"(function (_ENV)
	inherit "Controller"

	__HttpMethod__( )
	function Index(self)
		return self:Text("The query ID is " .. tostring(self.Id) .. "\n")
	end
end)
