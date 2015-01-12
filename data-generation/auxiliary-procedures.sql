use pachuta_a

if object_id('addClientCompanyIfNotExists') is not null drop procedure addClientCompanyIfNotExists;
go
create procedure addClientCompanyIfNotExists
	@CompanyName varchar(200),
	@Street varchar(200),
	@PostalCode varchar(6),
	@City varchar(200),
	@Country varchar(200),
	@Login varchar(200),
	@Password varchar(200),
	@Mail varchar(200),
	@Phone varchar(11),
	@BankAccount varchar(32)
as begin
	set nocount on
	if not exists (select * from Client where [Login] = @Login)
		exec addClientCompany
				@CompanyName,
				@Street,
				@PostalCode,
				@City,
				@Country,
				@Login,
				@Password,
				@Mail,
				@Phone,
				@BankAccount
end
go

if object_id('addClientPersonIfNotExists') is not null drop procedure addClientPersonIfNotExists;
go
create procedure addClientPersonIfNotExists
	@FirstName varchar(200),
	@LastName varchar(200),
	@Street varchar(200),
	@PostalCode varchar(6),
	@City varchar(200),
	@Country varchar(200),
	@Login varchar(200),
	@Password varchar(200),
	@Mail varchar(200),
	@Phone varchar(11),
	@BankAccount varchar(32),
	@IndexNumber varchar(6)= null
as begin
	set nocount on
	if not exists (select * from Client where [Login] = @Login)
		exec addClientPerson
			@FirstName,
			@LastName,
			@Street,
			@PostalCode,
			@City,
			@Country,
			@Login,
			@Password,
			@Mail,
			@Phone,
			@BankAccount,
			@IndexNumber
end
go

if object_id('addWorkshopTypeIfNotExists') is not null drop procedure addWorkshopTypeIfNotExists;
go
create procedure addWorkshopTypeIfNotExists
	@WorkshopTypeName varchar(200),
	@Capacity int,
	@Price money
as begin
	set nocount on
	if not exists (select * from WorkshopType where Name = @WorkshopTypeName)
	exec addWorkshopType
		@WorkshopTypeName,
		@Capacity,
		@Price
end
go
