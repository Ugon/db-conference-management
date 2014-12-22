IF OBJECT_ID('addNewPrice') IS NOT NULL 
DROP PROC addNewPrice;
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
DROP PROC Dodaj_Rezerwacje_Warsztatu
GO


CREATE PROCEDURE addNewPrice
	@ConferenceName varchar(255),
	@StartTime dateTime,
	@EndTime dateTime,
	@Discount float
AS
BEGIN
	SET NOCOUNT ON;
	
	declare @conferenceId int;
	declare @otherPrice int;
	
	set @conferenceId = dbo.getConferenceId(@ConferenceName);
	--sprawdzenie, czy w danym przedziale nie jest juz zdefiniowana znizka
	set @otherPrice = (select top 1 EarlyBirdDiscountID from EarlyBirdDiscount
		where StartTime Between @StartTime and @EndTime 
		or EndTime Between @StartTime and @EndTime)
		
	if @otherPrice is null
	begin
		print N'Wszystko ok';
		insert into EarlyBirdDiscount(ConferenceID,StartTime,EndTime,Discount)
		values (@conferenceId, @StartTime, @EndTime, @Discount)
	end
	else print N'Istnieje juz cena w zadanym przedziale.';
	
END
GO

CREATE procedure addClientCompany
	@CompanyName varchar(255),
	@Street varchar(255),
	@PostalCode varchar(255),
	@City varchar(255),
	@Country varchar(255),
	@Login varchar(255),
	@Password varchar(255),
	@Mail varchar(255),
	@Phone varchar(255),
	@BankAccount varchar(255)
	AS
	BEGIN
		set nocount on;
		declare @addressId int --id adresu ktory dodajemy
		declare @clientId int --id utworzonego klienta
		insert into Address(Street, PostalCode, City, Country) 
		values (@Street, @PostalCode, @City, @Country)
		set @addressId = scope_identity()
		insert into Client(AddressId, Login, Password, Mail, Phone, BankAccount,
			PastReservationCount,TotalMoneySpent) values
			(@addressId, @Login, @Password, @Mail, @Phone, @BankAccount, 0, 0)
		set @clientId = SCOPE_IDENTITY()
		
		insert into Company(ClientId, CompanyName) values (@clientId, @CompanyName)
	END
GO


CREATE PROCEDURE addClientPerson
	@FirstName varchar(255),
	@LastName varchar(255),
	@Street varchar(255),
	@PostalCode varchar(255),
	@City varchar(255),
	@Country varchar(255),
	@Login varchar(255),
	@Password varchar(255),
	@Mail varchar(255),
	@Phone varchar(255),
	@BankAccount varchar(255),
	@IndexNumber varchar(255)= null
AS
BEGIN
	SET NOCOUNT ON;
	declare @personId Int;
	declare @addressId Int;
	declare @clientId Int;
	--tworzenie rekordu Person
	insert into Person(FirstName,LastName)
		values (@FirstName, @LastName)
	set @personId = SCOPE_IDENTITY();
	--tworzenie rekordu Address
	insert into Address(Street,PostalCode,City,Country)
		values(@Street,@PostalCode,@City,@Country)
	set @addressId = SCOPE_IDENTITY();
	--tworzenie rekordu Client
	insert into Client(AddressID,Login,Password,Mail,Phone,BankAccount,
		PastReservationCount,TotalMoneySpent) values
		(@addressId,@Login,@Password,@Mail,@Phone,@BankAccount,0,0)
	set @clientId = SCOPE_IDENTITY();
	--tworzenie rekordu PersonClient
	insert into PersonClient(ClientID,PersonID,IndexNumber) 
		values (@clientId,@personId,@IndexNumber)
END
GO


CREATE PROCEDURE addConference
	@Name varchar(255),
	@Venue varchar(255),
	@DayPrice money,
	@StudentDiscount float,
	@Street varchar(255),
	@PostalCode varchar(255),
	@City varchar(255),
	@Country varchar(255)
AS
BEGIN
	SET NOCOUNT ON;
	declare @addressId int;
	--sprawdzanie, czy taki adres jest juz w bazie
	set @addressId = (select AddressId from Address where
		Street = @Street and PostalCode = @PostalCode and City = @City 
		and Country =@Country)
	--jesli nie istnieje adres - dodaj go i zapisz jego id w zmiennej
	if @addressId is null
	begin
		insert into Address(Street,PostalCode,City,Country)
		values(@Street,@PostalCode,@City,@Country)
		set @addressId = SCOPE_IDENTITY();
	end
	--dodanie rekordu nowej konferencji
	insert into Conference(AddressID,Name,Venue,DayPrice,StudentDiscount)
		values(@addressId,@Name,@Venue,@DayPrice,@StudentDiscount)
END
GO

CREATE PROCEDURE addConferenceDay
	@ConferenceName varchar(255),
	@Date date,
	@Capacity int
AS
BEGIN
	SET NOCOUNT ON;
	declare @conferenceId int;
	
	set @conferenceId = dbo.getConferenceId(@ConferenceName);
	
	insert into Day(ConferenceID, Date, Capacity,SlotsLeft)
		values(@conferenceId, @Date, @Capacity, @Capacity)
END
GO

CREATE PROCEDURE addWorkshop
	@WorkshopDate date,
	@ConferenceName varchar(255),
	@Name varchar(255),
	@StartTime time(7),
	@EndTime time(7),
	@Capacity int,
	@Price money,
	@Location varchar(255)
AS
BEGIN
	SET NOCOUNT ON;
	declare @typeId int;
	declare @dayId int;
	set @typeId = (select WorkshopTypeID from WorkshopType 
		where Name=@Name and Location = @Location and Price = @Price
		and Capacity = @Capacity and StartTime = @StartTime and EndTime = @EndTime)
	
	if @typeId is null
	begin
		insert into WorkshopType(Name, Capacity, Price, Location, StartTime, EndTime)
			values(@Name, @Capacity, @Price, @Location, @StartTime, @EndTime)
		set @typeId = SCOPE_IDENTITY();
	end	

	set @dayId = dbo.getConferenceDayId(@ConferenceName, @WorkshopDate)

	insert into WorkshopInstance(DayID,WorkshopTypeID,SlotsLeft)
		values(1, @typeId, @Capacity)
END
GO

CREATE PROCEDURE addNewPerson
	@FirstName varchar(255),
	@LastName varchar(255)
AS
BEGIN
	SET NOCOUNT ON;
	insert into Person(FirstName, LastName)
		values(@FirstName, @LastName)
END
GO



