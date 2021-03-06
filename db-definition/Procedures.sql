use pachuta_a
go

IF OBJECT_ID('addPayment') IS NOT NULL
DROP PROCEDURE addPayment
GO

CREATE procedure addPayment
	@ReservationID int,
	@payment money
AS
BEGIN
	update Reservation set Paid = Paid + @payment 
		where ReservationID = @ReservationID
END
GO

IF OBJECT_ID('insertIfNotExistsAddress') IS NOT NULL 
DROP PROC insertIfNotExistsAddress;
GO

CREATE procedure insertIfNotExistsAddress
	@Country varchar(200),
	@City varchar(200),
	@Street varchar(200),
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
	@FirstName varchar(200),
	@LastName varchar(200),
	@Mail varchar(200),
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
	@ConferenceName varchar(200),
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
	@Name varchar(200),
	@Venue varchar(200),
	@DayPrice money,
	@StudentDiscount float,
	@Street varchar(200),
	@PostalCode varchar(6),
	@City varchar(200),
	@Country varchar(200)
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
	@ConferenceName varchar(200),
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
	@WorkshopTypeName varchar(200),
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
	@WorkshopTypeName varchar(200),
	@ConferenceName varchar(200),
	@StartTime time(7), 
	@EndTime time(7), 
	@WorkshopDate date,
	@Location varchar(200)
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

IF OBJECT_ID('addWorkshopReservationDetailsForCompany') IS NOT NULL
DROP PROCEDURE addWorkshopReservationDetailsForCompany
GO

CREATE PROCEDURE addWorkshopReservationDetailsForCompany
	@ReservationID int,
	@ConferenceName varchar(200),
	@WorkshopName varchar(200),
	@Date date,
	@StartTime time,
	@FirstName varchar(200),
	@LastName varchar(200),
	@Mail varchar(200),
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
		
	set @dayId = dbo.getConferenceDayId(@ConferenceName, @Date);
		
	set @dayReservationId = (select DayReservationId from DayReservation 
		where ReservationID = @ReservationID and DayID = @dayId)
		
	set @dayReservationDetailsId = (select DayReservationDetailsId from DayReservationDetails 
		where PersonID = @personId and DayReservationID = @dayReservationId)

	set @workshopInstanceId = (select WorkshopInstanceId from WorkshopInstance
		where DayID = @dayId and StartTime = @StartTime 
		and WorkshopTypeID = (select WorkshopTypeID from WorkshopType where Name = @WorkshopName))	
		
	set @workshopReservationId = (select WorkshopReservationID from WorkshopReservation
		where DayReservationID = @dayReservationId and WorkshopInstanceID = @workshopInstanceId)
		
	insert into WorkshopReservationDetails(DayReservationDetailsID, WorkshopReservationID)
		values(@dayReservationDetailsId, @workshopReservationId)
		
END
GO

IF OBJECT_ID('addDayReservationDetailsForCompany') IS NOT NULL
DROP PROCEDURE addDayReservationDetailsForCompany
GO

CREATE PROCEDURE addDayReservationDetailsForCompany
	@ReservationID int,
	@ConferenceName varchar(200),
	@Date date,
	@FirstName varchar(200),
	@LastName varchar(200),
	@Mail varchar(200),
	@IndexNumber varchar(6) = null
AS
BEGIN 
	SET NOCOUNT ON;
	declare @dayReservationId int;
	declare @dayId int;
	declare @personId int;
	
	set @dayId = dbo.getConferenceDayId(@ConferenceName, @Date);
	
	set @dayReservationId = (select DayReservationID from DayReservation
		where DayID = @dayId and ReservationID = @ReservationID)
		
	exec insertPersonIfNotExists @FirstName, @LastName, @Mail, @IndexNumber
	
	set @personId = (select PersonId from Person where Mail = @Mail)
	
	if @IndexNumber is null 
		insert into DayReservationDetails(DayReservationID, PersonID, Student)
			values(@dayReservationId, @personId, 0)
	else
        insert into DayReservationDetails(DayReservationID, PersonID, Student)
			values(@dayReservationId, @personId, 1)
END
GO 

IF OBJECT_ID('addNewReservation') IS NOT NULL
DROP PROCEDURE addNewReservation
GO

CREATE PROCEDURE addNewReservation
	@Login varchar(200),
	@ReservationTime datetime = null,
	@ReservationID int output
AS
BEGIN
	SET NOCOUNT ON;
	declare @clientId int;
	
	set @clientId = (select ClientId from Client where Login = @Login)
	
	if @ReservationTime is null insert into Reservation(ClientID) values(@clientId)
	else insert into Reservation(ClientID, ReservationTime) values(@clientId, @ReservationTime)

		
	set @ReservationID = SCOPE_IDENTITY();
	
END
GO 

IF OBJECT_ID('addDayReservationForCompany') IS NOT NULL
DROP PROCEDURE addDayReservationForCompany
GO

CREATE PROCEDURE addDayReservationForCompany
	@ReservationID int,
	@ConferenceName varchar(200),
	@Date date,
	@NumberOfParticipants int,
	@NumberOfStudentDiscounts int
AS
BEGIN
	SET NOCOUNT ON;
	
	declare @dayId int;
	
	set @dayId = dbo.getConferenceDayId(@ConferenceName, @Date)
		
	insert into DayReservation(DayID, ReservationID, NumberOfParticipants, NumberOfStudentDiscounts)
		values (@dayId, @ReservationID, @NumberOfParticipants, @NumberOfStudentDiscounts)
END
GO

IF OBJECT_ID('addWorkshopReservationForCompany') IS NOT NULL
DROP PROCEDURE addWorkshopReservationForCompany
GO

CREATE PROCEDURE addWorkshopReservationForCompany
	@ReservationID int,
	@ConferenceName varchar(200),
	@WorkshopName varchar(200),
	@Date date,
	@StartTime time,
	@NumberOfParticipants int,
	@NumberOfStudentDiscounts int
AS 
BEGIN
	SET NOCOUNT ON;
	declare @workshopInstanceId int;
	declare @dayId int;
	declare @dayReservationId int;
	
	set @dayId = dbo.getConferenceDayId(@ConferenceName, @Date)
	
	set @workshopInstanceId = (select WorkshopInstanceId from WorkshopInstance
		where DayID = @dayId and StartTime = @StartTime 
		and WorkshopTypeID = (select WorkshopTypeID from WorkshopType where Name = @WorkshopName))
		
	set @dayReservationId = (select DayReservationId from DayReservation where DayID = @dayId
		and ReservationID = @ReservationID)
		
	insert into WorkshopReservation(WorkshopInstanceID, DayReservationID, 
		NumberOfParticipants, NumberOfStudentDiscounts)
		values(@workshopInstanceId, @dayReservationId ,@NumberOfParticipants, @NumberOfStudentDiscounts)
END
GO

IF OBJECT_ID('removeWorkshopReservationDetailsForCompany') IS NOT NULL
DROP PROCEDURE removeWorkshopReservationDetailsForCompany
GO

CREATE PROCEDURE removeWorkshopReservationDetailsForCompany
	@ReservationID int,
	@ConferenceName varchar(200),
	@WorkshopName varchar(200),
	@Date date,
	@StartTime time,
	@Mail varchar(200)
AS
BEGIN
	declare @dayReservationId int;
	declare @personId int;
	declare @dayReservationDetailsId int;
	declare @workshopInstanceId int;
	
	set @dayReservationId = (select DayReservationId from DayReservation 
		where DayID = dbo.getConferenceDayId(@ConferenceName, @Date) and ReservationID = @ReservationID)
	
	set @personId = (select PersonId from Person where Mail = @Mail)
		
	set @dayReservationDetailsId = (select DayReservationDetailsId from DayReservationDetails
		where PersonID = @personId and DayReservationID = @dayReservationId)
		
	set @workshopInstanceId = (select WorkshopInstanceId from WorkshopInstance
		where DayID = dbo.getConferenceDayId(@ConferenceName, @Date) 
		and WorkshopTypeID = (select WorkshopTypeID from WorkshopType where Name = @WorkshopName)
		and StartTime = @StartTime)
		
	delete from WorkshopReservationDetails 
		where DayReservationDetailsID = @dayReservationDetailsId 
		and WorkshopReservationID = (select WorkshopReservationID from WorkshopReservation
		where WorkshopInstanceID = @workshopInstanceId and DayReservationID = @dayReservationId)
		
		
END
GO

IF OBJECT_ID('removeDayReservationDetailsForCompany') IS NOT NULL
DROP PROCEDURE removeDayReservationDetailsForCompany
GO

CREATE PROCEDURE removeDayReservationDetailsForCompany
	@ReservationID int,
	@ConferenceName varchar(200),
	@Date date,
	@Mail varchar(200)
AS
BEGIN
	declare @dayReservationId int;
	declare @personId int;
	
	set @dayReservationId = (select DayReservationId from DayReservation 
		where DayID = dbo.getConferenceDayId(@ConferenceName, @Date) and ReservationID = @ReservationID)
	
	set @personId = (select PersonId from Person where Mail = @Mail)
		
	delete from DayReservationDetails
		where PersonID = @personId and DayReservationID = @dayReservationId
	
END
GO

if object_id('addDayReservationForPerson') is not null drop procedure addDayReservationForPerson;
go
create procedure addDayReservationForPerson
	@ReservationID int,
	@ConferenceName varchar(200),
	@Date date,
	@FirstName varchar(200),
	@LastName varchar(200),
	@Mail varchar(200),
	@IndexNumber varchar(6) = null
as begin
	declare @NumberOfStudentDiscounts int = 0
	if @IndexNumber is not null set @NumberOfStudentDiscounts = 1

	exec addDayReservationForCompany
		@ReservationID,
		@ConferenceName,
		@Date,
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = @NumberOfStudentDiscounts

	exec addDayReservationDetailsForCompany
		@ReservationID,
		@ConferenceName,
		@Date,
		@FirstName,
		@LastName,
		@Mail,
		@IndexNumber
end
go


if object_id('addWorkshopReservationForPerson') is not null drop procedure addWorkshopReservationForPerson;
go
create procedure addWorkshopReservationForPerson
	@ReservationID int,
	@ConferenceName varchar(200),
	@WorkshopName varchar(200),
	@Date date,
	@StartTime time,
	@FirstName varchar(200),
	@LastName varchar(200),
	@Mail varchar(200),
	@IndexNumber varchar(6) = null
as begin
	declare @NumberOfStudentDiscounts int = 0
	if @IndexNumber is not null set @NumberOfStudentDiscounts = 1
	
	exec addWorkshopReservationForCompany
		@ReservationID,
		@ConferenceName,
		@WorkshopName,
		@Date,
		@StartTime,
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = @NumberOfStudentDiscounts

	exec addWorkshopReservationDetailsForCompany
		@ReservationID,
		@ConferenceName,
		@WorkshopName,
		@Date,
		@StartTime,
		@FirstName,
		@LastName,
		@Mail,
		@IndexNumber
end
go

if object_id('cancelReservationForClient') is not null drop procedure cancelReservationForClient;
go
create procedure cancelReservationForClient
	@ReservationID int
as update Reservation set Cancelled = 1 where ReservationID = @ReservationID
go

if object_id('cancelReservationForOrganiser') is not null drop procedure cancelReservationForOrganiser;
go
create procedure cancelReservationForOrganiser
	@ReservationID int,
	@moneyToReturn money output
as 
	set @moneyToReturn = (select Paid from Reservation where ReservationId = @ReservationID)
	update Reservation set Cancelled = 1 where ReservationID = @ReservationID
go

IF OBJECT_ID('changeParticipantsStudentStatus') IS NOT NULL 
DROP PROC changeParticipantsStudentStatus
GO

CREATE PROCEDURE changeParticipantsStudentStatus
	@reservationId int,
	@conferenceName varchar(200),
	@date date,
	@mail varchar(200)
AS
BEGIN
	declare @currentStatus bit;
	declare @dayReservationDetailsId int;
	declare @newStudentValue bit;

	set @dayReservationDetailsId = (
		select DayReservationDetailsId 
		from DayReservation DR
		inner join DayReservationDetails DRD on DR.DayReservationID = DRD.DayReservationID
		inner join Person P on P.PersonID = DRD.PersonID
		where DR.ReservationID = @reservationId 
		and DayID = dbo.getConferenceDayId(@conferenceName, @date)
		and P.Mail = @mail
	)

	set @currentStatus = (select Student 
		from DayReservationDetails 
		where DayReservationDetailsID = @dayReservationDetailsId)

	if @currentStatus = 0
		set @newStudentValue = 1;
	else
		set @newStudentValue = 0;

	update DayReservationDetails 
		set Student = @newStudentValue 
		where DayReservationDetailsID = @dayReservationDetailsId
END
GO

IF OBJECT_ID('changeNumberOfParticipantsDay') IS NOT NULL 
DROP PROC changeNumberOfParticipantsDay
GO

CREATE procedure changeNumberOfParticipantsDay
	@reservationId int,
	@conferenceName varchar(200),
	@date date,
	@newNumberOfParticipants int
AS
BEGIN
	update DayReservation set NumberOfParticipants = @newNumberOfParticipants
	where ReservationID = @reservationId and DayId = (dbo.getConferenceDayId(@conferenceName, @date))
END
GO

IF OBJECT_ID('changeNumberOfStudentsDay') IS NOT NULL 
DROP PROC changeNumberOfStudentsDay
GO

CREATE procedure changeNumberOfStudentsDay
	@reservationId int,
	@conferenceName varchar(200),
	@date date,
	@newNumberOfStudentDiscounts int
AS
BEGIN
	update DayReservation set NumberOfStudentDiscounts = @newNumberOfStudentDiscounts
	where ReservationID = @reservationId and DayId = (dbo.getConferenceDayId(@conferenceName, @date))
END
GO

IF OBJECT_ID('changeDayReservationNumbers') IS NOT NULL 
DROP PROC changeDayReservationNumbers
GO

CREATE procedure changeDayReservationNumbers
	@reservationId int,
	@conferenceName varchar(200),
	@date date,
	@newNumberOfParticipants int,
	@newNumberOfStudentDiscounts int
AS
BEGIN
	update DayReservation set NumberOfParticipants = @newNumberOfParticipants,
		NumberOfStudentDiscounts = @newNumberOfStudentDiscounts
	where ReservationID = @reservationId and DayId = (dbo.getConferenceDayId(@conferenceName, @date))
END
GO

IF OBJECT_ID('changeNumberOfParticipantsWorkshop') IS NOT NULL 
DROP PROC changeNumberOfParticipantsWorkshop
GO

CREATE procedure changeNumberOfParticipantsWorkshop
	@reservationId int,
	@conferenceName varchar(200),
	@workshopName varchar(200),
	@date date,
	@startTime time,
	@newNumberOfParticipants int
AS
BEGIN
		update WorkshopReservation set NumberOfParticipants = @newNumberOfParticipants
		where 
		WorkshopReservationID = dbo.getWorkshopReservationId(@reservationId, @conferenceName, @workshopName, @date, @startTime)
END
GO

IF OBJECT_ID('changeNumberOfStudentsWorkshop') IS NOT NULL 
DROP PROC changeNumberOfStudentsWorkshop
GO

CREATE procedure changeNumberOfStudentsWorkshop
	@reservationId int,
	@conferenceName varchar(200),
	@workshopName varchar(200),
	@date date,
	@startTime time,
	@newNumberOfStudentDiscounts int
AS
BEGIN
	update WorkshopReservation set NumberOfStudentDiscounts = @newNumberOfStudentDiscounts
	where 
	WorkshopReservationID = dbo.getWorkshopReservationId(@reservationId, @conferenceName, @workshopName, @date, @startTime)
END
GO


IF OBJECT_ID('changeWorkshopReservationNumbers') IS NOT NULL 
DROP PROC changeWorkshopReservationNumbers
GO

CREATE procedure changeWorkshopReservationNumbers
	@reservationId int,
	@conferenceName varchar(200),
	@workshopName varchar(200),
	@date date,
	@startTime time,
	@newNumberOfParticipants int,
	@newNumberOfStudentDiscounts int
AS
BEGIN
	update WorkshopReservation set NumberOfParticipants = @newNumberOfParticipants,
		NumberOfStudentDiscounts = @newNumberOfStudentDiscounts
	where
	 WorkshopReservationID = dbo.getWorkshopReservationId(@reservationId, @conferenceName, @workshopName, @date, @startTime)

END
GO

IF OBJECT_ID('cancelDayReservation') IS NOT NULL 
DROP PROC cancelDayReservation
GO

CREATE procedure cancelDayReservation
	@reservationId int,
	@conferenceName varchar(200),
	@date date
AS
BEGIN
	delete from DayReservation
	where ReservationId = @reservationId 
	and DayID = dbo.getConferenceDayId(@conferenceName, @date)
END
GO

IF OBJECT_ID('cancelWorkshopReservation') IS NOT NULL 
DROP PROC cancelWorkshopReservation
GO

CREATE procedure cancelWorkshopReservation
	@reservationId int,
	@conferenceName varchar(200),
	@workshopName varchar(200),
	@date date,
	@startTime time
AS
BEGIN
	delete from WorkshopReservation
	where
	WorkshopReservationID = dbo.getWorkshopReservationId(@reservationId, @conferenceName, @workshopName, @date, @startTime)

END
GO

IF OBJECT_ID('removeDayReservationForPerson') IS NOT NULL 
DROP PROC removeDayReservationForPerson
GO

CREATE PROCEDURE removeDayReservationForPerson
	@reservationId int,
	@conferenceName varchar(200),
	@date date,
	@mail varchar(200)
AS
BEGIN
	declare @personId int;
	declare @dayReservationDetailsId int;

	set @personId = (select PersonId from Person where Mail = @mail)
	set @dayReservationDetailsId = (select DayReservationDetailsID from DayReservationDetails
		where PersonId = @personId)

	delete from DayReservationDetails
	where DayReservationDetailsID = @dayReservationDetailsId
		and DayReservationID = dbo.getDayReservationId(@reservationId, @conferenceName, @date)
END
GO

IF OBJECT_ID('removeWorkshopReservationForPerson') IS NOT NULL 
DROP PROC removeWorkshopReservationForPerson
GO

CREATE PROCEDURE removeWorkshopReservationForPerson
	@reservationId int,
	@conferenceName varchar(200),
	@workshopName varchar(200),
	@date date,
	@startTime time,
	@mail varchar(200)
AS
BEGIN
	declare @personId int;
	declare @dayReservationDetailsId int;
	declare @workshopReservationID int;

	set @personId = (select PersonId from Person where Mail = @mail)

	set @dayReservationDetailsId = (
		select DayReservationDetailsID 
		from DayReservationDetails
		where PersonID = @personId
		and DayReservationId = dbo.getDayReservationId(@reservationId,@conferenceName, @date)
	)

	set @workshopReservationID = dbo.getWorkshopReservationId(@reservationId, @conferenceName, @workshopName, @date, @startTime)

	delete from WorkshopReservationDetails
	where DayReservationDetailsID = @dayReservationDetailsId
	and WorkshopReservationID = @workshopReservationID
END
GO

IF OBJECT_ID('changeConferenceDayCapacity') IS NOT NULL 
DROP PROC changeConferenceDayCapacity
GO

CREATE PROCEDURE changeConferenceDayCapacity
	@conferenceName varchar(200),
	@date date,
	@newCapacity int
AS
BEGIN
	update Day set Capacity = @newCapacity
	where DayId = dbo.getConferenceDayId(@conferenceName, @date)
END
GO

IF OBJECT_ID('changeWorkshopTypeCapacity') IS NOT NULL 
DROP PROC changeWorkshopTypeCapacity
GO

CREATE PROCEDURE changeWorkshopTypeCapacity
	@workshopName varchar(200),
	@newCapacity int
AS
BEGIN
	update WorkshopType set Capacity = @newCapacity
	where Name=@workshopName
END
GO

