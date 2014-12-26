use pachuta_a

IF OBJECT_ID('addEarlyBirdDiscount') IS NOT NULL 
DROP PROC addEarlyBirdDiscount;
GO
IF OBJECT_ID('addClientCompany') IS NOT NULL 
DROP PROC addClientCompany;
GO
IF OBJECT_ID('addClientPerson') IS NOT NULL 
DROP PROC addClientPerson;
GO
IF OBJECT_ID('addConference') IS NOT NULL 
DROP PROC addConference;
GO
IF OBJECT_ID('addConferenceDay') IS NOT NULL 
DROP PROC addConferenceDay;
GO
IF OBJECT_ID('addWorkshop') IS NOT NULL
DROP PROC addWorkshop;
GO
IF OBJECT_ID('addNewPerson') IS NOT NULL
DROP PROC addNewPerson
GO
IF OBJECT_ID('insertIfNotExistsAddress') IS NOT NULL 
DROP PROC insertIfNotExistsAddress;
GO

IF OBJECT_ID('addWorkshopInstance') IS NOT NULL 
DROP PROC addWorkshopInstance;
GO

IF OBJECT_ID('addWorkshopType') IS NOT NULL 
DROP PROC addWorkshopType;
GO


CREATE procedure insertIfNotExistsAddress
	@Country varchar(50),
	@City varchar(50),
	@Street varchar(50),
	@PostalCode varchar(6)
AS
BEGIN
	if not exists (select * from [Address] as a 
		where a.Country = @Country and a.City = @City and a.Street = @Street and a.PostalCode = @PostalCode)
	insert into [Address](Country, City, Street, PostalCode) 
		values (@Country, @City, @Street, @PostalCode)
END
GO

CREATE PROCEDURE addEarlyBirdDiscount
	@ConferenceName varchar(50),
	@StartTime dateTime,
	@EndTime dateTime,
	@Discount float
AS
BEGIN
	SET NOCOUNT ON;
	declare @conferenceId int;
	
	set @conferenceId = dbo.getConferenceId(@ConferenceName);
		
	insert into EarlyBirdDiscount(ConferenceID,StartTime,EndTime,Discount)
		values (@conferenceId, @StartTime, @EndTime, @Discount)

END
GO

CREATE procedure addClientCompany
	@CompanyName varchar(50),
	@Street varchar(50),
	@PostalCode varchar(6),
	@City varchar(50),
	@Country varchar(50),
	@Login varchar(50),
	@Password varchar(50),
	@Mail varchar(50),
	@Phone varchar(11),
	@BankAccount varchar(32)
AS
BEGIN
		set nocount on;
		declare @addressId int --id adresu ktory dodajemy
		declare @clientId int --id utworzonego klienta
			
		exec insertIfNotExistsAddress @Country, @City, @Street, @PostalCode
		
		set @addressId = (select a.AddressID from [Address] as a 
			where a.Country = @Country and a.City = @City and 
			a.Street = @Street and a.PostalCode = @PostalCode)	
		
		insert into Client(AddressId, Login, Password, Phone, BankAccount) values
			(@addressId, @Login, @Password, @Phone, @BankAccount)
			
		set @clientId = SCOPE_IDENTITY()
		
		insert into Company(ClientId, CompanyName, Mail) values (@clientId, @CompanyName, @Mail)
END
GO


CREATE PROCEDURE addClientPerson
	@FirstName varchar(50),
	@LastName varchar(50),
	@Street varchar(50),
	@PostalCode varchar(6),
	@City varchar(50),
	@Country varchar(50),
	@Login varchar(50),
	@Password varchar(50),
	@Mail varchar(50),
	@Phone varchar(11),
	@BankAccount varchar(32),
	@IndexNumber varchar(6)= null
AS
BEGIN
	SET NOCOUNT ON;
	declare @personId Int;
	declare @addressId Int;
	declare @clientId Int;
	
	--tworzenie rekordu Person
	insert into Person(FirstName,LastName, Mail)
		values (@FirstName, @LastName, @Mail)
		
	set @personId = SCOPE_IDENTITY();
	
	--tworzenie rekordu Address
	exec insertIfNotExistsAddress @Country, @City, @Street, @PostalCode
		
	set @addressId = (select a.AddressID from [Address] as a 
		where a.Country = @Country and a.City = @City and 
		a.Street = @Street and a.PostalCode = @PostalCode)
	
	--tworzenie rekordu Client
	insert into Client(AddressID,Login,Password,Phone,BankAccount) 
		values (@addressId, @Login, @Password, @Phone, @BankAccount)
		
	set @clientId = SCOPE_IDENTITY();
	
	--tworzenie rekordu PersonClient
	insert into PersonClient(ClientID,PersonID,IndexNumber) 
		values (@clientId,@personId,@IndexNumber)
END
GO

CREATE PROCEDURE addConference
	@Name varchar(50),
	@Venue varchar(50),
	@DayPrice money,
	@StudentDiscount float,
	@Street varchar(50),
	@PostalCode varchar(6),
	@City varchar(50),
	@Country varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	declare @addressId int;
	
	exec insertIfNotExistsAddress @Country, @City, @Street, @PostalCode
	
	set @addressId = (select a.AddressID from [Address] as a 
		where a.Country = @Country and a.City = @City and a.Street = @Street and a.PostalCode = @PostalCode)
		
	--dodanie rekordu nowej konferencji
	insert into Conference(AddressID,Name,Venue,DayPrice,StudentDiscount)
		values(@addressId,@Name,@Venue,@DayPrice,@StudentDiscount)
END
GO


CREATE PROCEDURE addConferenceDay
	@ConferenceName varchar(50),
	@Date date,
	@Capacity int
AS
BEGIN
	SET NOCOUNT ON;
	declare @conferenceId int;
	
	set @conferenceId = dbo.getConferenceId(@ConferenceName);
	
	insert into Day(ConferenceID, Date, Capacity)
		values(@conferenceId, @Date, @Capacity)
END
GO

CREATE PROCEDURE addNewPerson
	@FirstName varchar(50),
	@LastName varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	insert into Person(FirstName, LastName)
		values(@FirstName, @LastName)
END
GO

CREATE PROCEDURE addWorkshopType
	@WorkshopTypeName varchar(50),
	@Capacity int,
	@Price money
AS
BEGIN
	SET NOCOUNT ON;
	insert into WorkshopType(Name, Capacity, Price)
		values(@WorkshopTypeName, @Capacity, @Price)
END
GO

CREATE PROCEDURE addWorkshopInstance
	@WorkshopTypeName varchar(50),
	@ConferenceName varchar(50),
	@StartTime time(7), 
	@EndTime time(7), 
	@WorkshopDate date,
	@Location varchar(50)
AS
BEGIN
	declare @dayId int;
	declare @WorkshopTypeId int;
	
	set @WorkshopTypeId = (select WorkshopTypeID from WorkshopType 
		where Name = @WorkshopTypeName)
	
	set @dayId = (select DayID from Day where Date = @WorkshopDate 
		and ConferenceID = (select ConferenceID from Conference where Name = @ConferenceName))
	
	insert into WorkshopInstance(DayID,Location,WorkshopTypeID,StartTime,EndTime)
		values (@dayId, @Location, @WorkshopTypeId, @StartTime, @EndTime)
END
GO