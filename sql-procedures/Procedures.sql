use pachuta_a

IF OBJECT_ID('addPayment') IS NOT NULL
DROP PROCEDURE addPayment
GO

CREATE procedure addPayment
	@reservationId int,
	@payment money
AS
BEGIN
	update Reservation set Paid = Paid + @payment 
		where ReservationID = @reservationId
END
GO

IF OBJECT_ID('insertIfNotExistsAddress') IS NOT NULL 
DROP PROC insertIfNotExistsAddress;
GO

CREATE procedure insertIfNotExistsAddress
	@Country varchar(50),
	@City varchar(50),
	@Street varchar(50),
	@PostalCode varchar(6)
AS
BEGIN
	SET NOCOUNT ON;
	if not exists (select * from [Address] as a 
		where a.Country = @Country and a.City = @City and a.Street = @Street and a.PostalCode = @PostalCode)
	insert into [Address](Country, City, Street, PostalCode) 
		values (@Country, @City, @Street, @PostalCode)
END
GO

IF OBJECT_ID('insertPersonIfNotExists') IS NOT NULL
DROP PROCEDURE insertPersonIfNotExists
GO

CREATE PROCEDURE insertPersonIfNotExists
	@FirstName varchar(50),
	@LastName varchar(50),
	@Mail varchar(50),
	@IndexNumber varchar(6) =  null
AS
BEGIN
	SET NOCOUNT ON;
	if not exists (select * from Person where FirstName = @FirstName and LastName = @LastName
		and Mail = @Mail)
	insert into Person(FirstName, LastName, Mail, IndexNumber) 
		values (@FirstName, @LastName, @Mail, @IndexNumber)
END
GO

IF OBJECT_ID('addEarlyBirdDiscount') IS NOT NULL 
DROP PROC addEarlyBirdDiscount;
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

IF OBJECT_ID('addClientCompany') IS NOT NULL 
DROP PROC addClientCompany;
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
		SET NOCOUNT ON;
		declare @addressId int
		declare @clientId int
			
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

IF OBJECT_ID('addClientPerson') IS NOT NULL 
DROP PROC addClientPerson;
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
	
	exec insertPersonIfNotExists @FirstName, @LastName, @Mail, @IndexNumber
	set @personId = (select PersonId from Person where Mail = @Mail)
	
	exec insertIfNotExistsAddress @Country, @City, @Street, @PostalCode
		
	set @addressId = (select a.AddressID from [Address] as a 
		where a.Country = @Country and a.City = @City and 
		a.Street = @Street and a.PostalCode = @PostalCode)
	
	insert into Client(AddressID,Login,Password,Phone,BankAccount) 
		values (@addressId, @Login, @Password, @Phone, @BankAccount)
		
	set @clientId = SCOPE_IDENTITY();
	
	insert into PersonClient(ClientID,PersonID)
		values (@clientId,@personId)
END
GO

IF OBJECT_ID('addConference') IS NOT NULL 
DROP PROC addConference;
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
		
	insert into Conference(AddressID,Name,Venue,DayPrice,StudentDiscount)
		values(@addressId,@Name,@Venue,@DayPrice,@StudentDiscount)
END
GO

IF OBJECT_ID('addConferenceDay') IS NOT NULL 
DROP PROC addConferenceDay;
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

IF OBJECT_ID('addWorkshopType') IS NOT NULL 
DROP PROC addWorkshopType;
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

IF OBJECT_ID('addWorkshopInstance') IS NOT NULL 
DROP PROC addWorkshopInstance;
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
	SET NOCOUNT ON;
	
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

--=============RESERVATIONS=============--

IF OBJECT_ID('addWorkshopReservationDetails') IS NOT NULL
DROP PROCEDURE addWorkshopReservationDetails
GO

CREATE PROCEDURE addWorkshopReservationDetails
	@reservationId int,
	@conferenceName varchar(50),
	@workshopName varchar(50),
	@date date,
	@startTime time,
	@FirstName varchar(50),
	@LastName varchar(50),
	@Mail varchar(50),
	@IndexNumber varchar(6) =  null
AS
BEGIN
	SET NOCOUNT ON;
	declare @dayReservationDetailsId int;
	declare @personId int;
	declare @dayReservationId int;
	declare @dayId int;
	declare @workshopInstanceId int;
	declare @workshopReservationId int;
	
	exec insertPersonIfNotExists @FirstName, @LastName, @Mail, @IndexNumber
	set @personId = (select PersonId from Person where Mail = @Mail)
		
	set @dayId = dbo.getConferenceDayId(@conferenceName, @date);
		
	set @dayReservationId = (select DayReservationId from DayReservation 
		where ReservationID = @reservationId and DayID = @dayId)
		
	set @dayReservationDetailsId = (select DayReservationDetailsId from DayReservationDetails 
		where PersonID = @personId and DayReservationID = @dayReservationId)
		
	if @dayReservationDetailsId is not null
	begin
		set @workshopInstanceId = (select WorkshopInstanceId from WorkshopInstance
		where DayID = @dayId and StartTime = @startTime 
		and WorkshopTypeID = (select WorkshopTypeID from WorkshopType where Name = @workshopName))	
		
		set @workshopReservationId = (select WorkshopReservationID from WorkshopReservation
			where DayReservationID = @dayReservationId and WorkshopInstanceID = @workshopInstanceId)
		
		insert into WorkshopReservationDetails(DayReservationDetailsID, WorkshopReservationID)
			values(@dayReservationDetailsId, @workshopReservationId)
		
	end
	else RAISERROR('Given person has no reservation for a conference',0,1)
END
GO

IF OBJECT_ID('addDayReservationDetails') IS NOT NULL
DROP PROCEDURE addDayReservationDetails
GO

CREATE PROCEDURE addDayReservationDetails
	@reservationId int,
	@conferenceName varchar(50),
	@date date,
	@FirstName varchar(50),
	@LastName varchar(50),
	@Mail varchar(50),
	@IndexNumber varchar(6) = null
AS
BEGIN 
	SET NOCOUNT ON;
	declare @dayReservationId int;
	declare @dayId int;
	declare @personId int;
	declare @student bit;
	
	set @dayId = dbo.getConferenceDayId(@conferenceName, @date);
	
	set @dayReservationId = (select DayReservationID from DayReservation
		where DayID = @dayId and ReservationID = @reservationId)
		
	exec insertPersonIfNotExists @FirstName, @LastName, @Mail, @IndexNumber
	
	set @personId = (select PersonId from Person where Mail = @Mail)
	
	if @IndexNumber is null begin
           insert into DayReservationDetails(DayReservationID, PersonID, Student)
				values(@dayReservationId, @personId, 0)
	end else begin try
           insert into DayReservationDetails(DayReservationID, PersonID, Student)
				values(@dayReservationId, @personId, 1)
	end try begin catch
           insert into DayReservationDetails(DayReservationID, PersonID, Student)
				values(@dayReservationId, @personId, 0)
	end catch
END
GO 

IF OBJECT_ID('addNewReservation') IS NOT NULL
DROP PROCEDURE addNewReservation
GO

CREATE PROCEDURE addNewReservation
	@Login varchar(50),
	@reservationId int output
AS
BEGIN
	SET NOCOUNT ON;
	declare @clientId int;
	
	set @clientId = (select ClientId from Client where Login = @Login)
	
	insert into Reservation(ClientID)
		values(@clientId)
		
	set @reservationId = SCOPE_IDENTITY();
	
END
GO 

IF OBJECT_ID('addDayReservation') IS NOT NULL
DROP PROCEDURE addDayReservation
GO

CREATE PROCEDURE addDayReservation
	@reservationId int,
	@conferenceName varchar(50),
	@date date,
	@NumberOfParticipants int,
	@NumberOfStudentDiscounts int
AS
BEGIN
	SET NOCOUNT ON;
	
	declare @dayId int;
	
	set @dayId = dbo.getConferenceDayId(@conferenceName, @date)
		
	insert into DayReservation(DayID, ReservationID, NumberOfParticipants, NumberOfStudentDiscounts)
		values (@dayId, @reservationId, @NumberOfParticipants, @NumberOfStudentDiscounts)
END
GO

IF OBJECT_ID('addWorkshopReservation') IS NOT NULL
DROP PROCEDURE addWorkshopReservation
GO

CREATE PROCEDURE addWorkshopReservation
	@reservationId int,
	@conferenceName varchar(50),
	@workshopName varchar(50),
	@date date,
	@startTime time,
	@NumberOfParticipants int,
	@NumberOfStudentDiscounts int
AS 
BEGIN
	SET NOCOUNT ON;
	declare @workshopInstanceId int;
	declare @dayId int;
	declare @dayReservationId int;
	
	set @dayId = dbo.getConferenceDayId(@conferenceName, @date)
	
	set @workshopInstanceId = (select WorkshopInstanceId from WorkshopInstance
		where DayID = @dayId and StartTime = @startTime 
		and WorkshopTypeID = (select WorkshopTypeID from WorkshopType where Name = @workshopName))
		
	set @dayReservationId = (select DayReservationId from DayReservation where DayID = @dayId
		and ReservationID = @reservationId)
		
	insert into WorkshopReservation(WorkshopInstanceID, DayReservationID, 
		NumberOfParticipants, NumberOfStudentDiscounts)
		values(@workshopInstanceId, @dayReservationId ,@NumberOfParticipants, @NumberOfStudentDiscounts)
END
GO

IF OBJECT_ID('removeWorkshopReservationDetails') IS NOT NULL
DROP PROCEDURE removeWorkshopReservationDetails
GO

CREATE PROCEDURE removeWorkshopReservationDetails
	@reservationId int,
	@conferenceName varchar(50),
	@workshopName varchar(50),
	@date date,
	@startTime time,
	@Mail varchar(50)
AS
BEGIN
	declare @dayReservationId int;
	declare @personId int;
	declare @dayReservationDetailsId int;
	declare @workshopInstanceId int;
	
	set @dayReservationId = (select DayReservationId from DayReservation 
		where DayID = dbo.getConferenceDayId(@conferenceName, @date) and ReservationID = @reservationId)
	
	set @personId = (select PersonId from Person where Mail = @Mail)
		
	set @dayReservationDetailsId = (select DayReservationDetailsId from DayReservationDetails
		where PersonID = @personId and DayReservationID = @dayReservationId)
		
	set @workshopInstanceId = (select WorkshopInstanceId from WorkshopInstance
		where DayID = dbo.getConferenceDayId(@conferenceName, @date) 
		and WorkshopTypeID = (select WorkshopTypeID from WorkshopType where Name = @workshopName)
		and StartTime = @startTime)
		
	delete from WorkshopReservationDetails 
		where DayReservationDetailsID = @dayReservationDetailsId 
		and WorkshopReservationID = (select WorkshopReservationID from WorkshopReservation
		where WorkshopInstanceID = @workshopInstanceId and DayReservationID = @dayReservationId)
		
		
END
GO

IF OBJECT_ID('removeDayReservationDetails') IS NOT NULL
DROP PROCEDURE removeDayReservationDetails
GO

CREATE PROCEDURE removeDayReservationDetails
	@reservationId int,
	@conferenceName varchar(50),
	@date date,
	@Mail varchar(50)
AS
BEGIN
	declare @dayReservationId int;
	declare @personId int;
	
	set @dayReservationId = (select DayReservationId from DayReservation 
		where DayID = dbo.getConferenceDayId(@conferenceName, @date) and ReservationID = @reservationId)
	
	set @personId = (select PersonId from Person where Mail = @Mail)
		
	delete from DayReservationDetails
		where PersonID = @personId and DayReservationID = @dayReservationId
	
END
GO