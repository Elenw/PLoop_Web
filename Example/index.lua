struct "Person" { Name = String, Age = Number}
struct "Persons" { Person }

class "index" {
	PageTitle = String,
	Data = Persons,
}

function index:OnLoad()
	self.PageTitle = "My First Page"

	self.Data = {
		Person("Ann", 12),
		Person("King", 32),
		Person("July", 22),
		Person("Sam", 30),
	}
end

