use test_db
go

exec tSQLt.DropClass 'calculateTriggersTest' 
go
exec tSQLt.NewTestClass 'calculateTriggersTest'
go

if object_id('dbo.getClientReservation') is not null 
drop function dbo.getClientReservation
go

create function getClientReservation(@Login varchar(200))
returns int
as
begin
	return (select ReservationID 
		from Reservation R
		inner join Client C on C.ClientID = R.ClientID
		where C.Login = @Login)
end
go

if object_id('[calculateTriggersTest].[setup]') is not null drop procedure [CompanyReservationTest].[setup]
go
create procedure [calculateTriggersTest].[setup] as begin

	exec dbo.addConference 
		@Name = 'Conference1',
		@Venue = 'Venue1',
		@DayPrice = 100,
		@StudentDiscount = 0.5,
		@Street = 'Street1',
		@PostalCode = '12-345',
		@City = 'Gotham City',
		@Country = 'Poland'

	exec dbo.addConferenceDay
		@ConferenceName = 'Conference1',
		@Date = '2015-10-01',
		@Capacity = 30

	exec dbo.addConferenceDay
		@ConferenceName = 'Conference1',
		@Date = '2015-10-02',
		@Capacity = 30
		
	exec dbo.addClientCompany
		@CompanyName = 'Company1',
		@Street = 'Street2',
		@PostalCode = '23-123',
		@City = 'Gotham City',
		@Country = 'Poland',
		@Login = 'cmp1',
		@Password = '1234',
		@Mail = 'cmp1@gmail.com',
		@Phone = '123 456 789',
		@BankAccount = '67 7777 2051 9315 7762 4007 8850'

	exec dbo.addClientCompany
		@CompanyName = 'Company2',
		@Street = 'Street3',
		@PostalCode = '23-123',
		@City = 'Gotham City',
		@Country = 'Poland',
		@Login = 'cmp2',
		@Password = '12345',
		@Mail = 'cmp2@gmail.com',
		@Phone = '123 456 987',
		@BankAccount = '76 7977 2051 9315 7762 4007 8850'


	exec dbo.addClientCompany
		@CompanyName = 'Company3',
		@Street = 'Street4',
		@PostalCode = '23-123',
		@City = 'Gotham City',
		@Country = 'Poland',
		@Login = 'cmp3',
		@Password = '123456',
		@Mail = 'cmp3@gmail.com',
		@Phone = '123 456 999',
		@BankAccount = '76 7999 2051 9315 7762 4007 8850'

	declare @testReservationId int;

	exec dbo.addNewReservation
		@Login = 'cmp1',
		@ReservationId = @testReservationId output

	exec dbo.addDayReservationForCompany
		@ReservationID = @testReservationId,
		@ConferenceName = 'Conference1',
		@Date = '2015-10-01',
		@NumberOfParticipants = 10,
		@NumberOfStudentDiscounts = 2

	exec dbo.addWorkshopType 
		@WorkshopTypeName = 'Workshop1',
		@Capacity = 20,
		@Price = 100

	exec dbo.addWorkshopInstance
		@WorkshopTypeName = 'Workshop1',
		@ConferenceName = 'Conference1',
		@StartTime = '8:00:00',
		@EndTime = '12:00:00',
		@WorkshopDate = '2015-10-01',
		@Location = 'Location1'

	exec dbo.addWorkshopReservationForCompany
		@ReservationId = @testReservationId,
		@ConferenceName = 'Conference1',
		@WorkshopName = 'Workshop1',
		@Date = '2015-10-01',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 10,
		@NumberOfStudentDiscounts = 2	

	exec dbo.addNewReservation
		@Login = 'cmp2',
		@ReservationId = @testReservationId output

	exec dbo.addDayReservationForCompany
		@ReservationID = @testReservationId,
		@ConferenceName = 'Conference1',
		@Date = '2015-10-01',
		@NumberOfParticipants = 10,
		@NumberOfStudentDiscounts = 2
end
go

--exec tSQLt.Run '[calculateTriggersTest].[testDataCreationProcess]' go
if object_id('[calculateTriggersTest].[testDataCreationProcess]') is not null 
drop procedure [calculateTriggersTest].[testDataCreationProcess]
go

create procedure [calculateTriggersTest].[testDataCreationProcess] as begin

	declare @ActualNumOfConferences int = (select count(*) from Conference)
	exec tSQLt.AssertEquals 1, @ActualNumOfConferences

	declare @ActualNumOfCompanyClients int = (select count(*) from Company)
	exec tSQLt.AssertEquals 2, @ActualNumOfCompanyClients

	declare @ActualNumOfReservations int = (select count(*) from Reservation)
	exec tSQLt.AssertEquals 2, @ActualNumOfReservations

	declare @ActualNumOfWorkshopReservation int = (select count(*) from WorkshopReservation)
	exec tSQLt.AssertEquals 1, @ActualNumOfWorkshopReservation

	declare @ActualNumOfWorkshopInstance int = (select count(*) from WorkshopInstance)
	exec tSQLt.AssertEquals 1, @ActualNumOfWorkshopInstance

	declare @ActualNumOfWorkshopType int = (select count(*) from WorkshopType)
	exec tSQLt.AssertEquals 1, @ActualNumOfWorkshopType

end 
go


--exec tSQLt.Run '[calculateTriggersTest].[testcalCulateReservationPriceShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testcalCulateReservationPriceShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testcalCulateReservationPriceShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testcalCulateReservationPriceShouldSUCCESS] as begin

	declare @testReservationId int =  dbo.getClientReservation('cmp2')

	declare @ActualDayReservationPrice int = (select Price from Reservation where ReservationID = @testReservationId)
	exec tSQLt.AssertEquals 900, @ActualDayReservationPrice

	exec dbo.addWorkshopReservationForCompany
		@ReservationId = @testReservationId,
		@ConferenceName = 'Conference1',
		@WorkshopName = 'Workshop1',
		@Date = '2015-10-01',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 1
		
	declare @ActualReservationForDayAndWorkshopPrice int = 	 (select Price from Reservation where ReservationID = @testReservationId)
	exec tSQLt.AssertEquals 1050, @ActualReservationForDayAndWorkshopPrice
	
end 
go

--exec tSQLt.Run '[calculateTriggersTest].[testDaySlotsFilledShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testDaySlotsFilledShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testSlotsFilledShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testDaySlotsFilledShouldSUCCESS] as begin
	declare @ActualNumOfDaySlotsFilled int = (
		select SlotsFilled from Day where DayID = dbo.getConferenceDayId('Conference1', '2015-10-01')
	)

	exec tSQLt.AssertEquals 20, @ActualNumOfDaySlotsFilled
end 
go

if object_id('[calculateTriggersTest].[testWorkshopSlotsFilledShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testSlotsFilledShouldSUCCESS]
go

--exec tSQLt.Run '[calculateTriggersTest].[testWorkshopSlotsFilledShouldSUCCESS]' go

create procedure [calculateTriggersTest].testWorkshopSlotsFilledShouldSUCCESS as begin
	declare @ActualNumOfWorkshopSlotsFilled int = (
		select SlotsFilled 
		from WorkshopInstance WI
		inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
		where DayID = dbo.getConferenceDayId('Conference1', '2015-10-01')
		and WT.Name = 'Workshop1' and StartTime = '8:00:00'
	)

	exec tSQLt.AssertEquals 10, @ActualNumOfWorkshopSlotsFilled
end 
go

--exec tSQLt.Run '[calculateTriggersTest].[testDaySlotsFilledAfterReservatinonCancelShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testDaySlotsFilledAfterReservatinonCancelShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testDaySlotsFilledAfterReservatinonCancelShouldSUCCESS]
go

create procedure [calculateTriggersTest].testDaySlotsFilledAfterReservatinonCancelShouldSUCCESS as begin
	
	declare @testReservationId int = dbo.getClientReservation('cmp2')

	exec cancelReservationForClient
		@ReservationId= @testReservationId

	declare @ActualNumOfDaySlotsFilled int = (
		select SlotsFilled from Day where DayID = dbo.getConferenceDayId('Conference1', '2015-10-01')
	)

	exec tSQLt.AssertEquals 10, @ActualNumOfDaySlotsFilled
end 
go

--exec tSQLt.Run '[calculateTriggersTest].[testWorkshopSlotsFilledAfterReservatinonCancelShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testWorkshopSlotsFilledAfterReservatinonCancelShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testWorkshopSlotsFilledAfterReservatinonCancelShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testWorkshopSlotsFilledAfterReservatinonCancelShouldSUCCESS] as begin
	
	declare @testReservationId int = dbo.getClientReservation('cmp1')
	
	exec cancelReservationForClient
		@ReservationId = @testReservationId

	declare @ActualNumOfWorkshopSlotsFilled int = (
		select SlotsFilled 
		from WorkshopInstance WI
		inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
		where DayID = dbo.getConferenceDayId('Conference1', '2015-10-01')
		and WT.Name = 'Workshop1' and StartTime = '8:00:00'
	)

	exec tSQLt.AssertEquals 0, @ActualNumOfWorkshopSlotsFilled
end 
go

--exec tSQLt.Run '[calculateTriggersTest].[testWorkshopSlotsFilledAfterDayReservatinonCancelShouldSUCCESS]'go
if object_id('[calculateTriggersTest].[testWorkshopSlotsFilledAfterDayReservatinonCancelShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testWorkshopSlotsFilledAfterDayReservatinonCancelShouldSUCCESS]
go

--exec tSQLt.Run '[calculateTriggersTest].[testWorkshopSlotsFilledAfterWorkshopReservatinonCancelShouldSUCCESS]' go
create procedure [calculateTriggersTest].testWorkshopSlotsFilledAfterDayReservatinonCancelShouldSUCCESS as begin

	declare @testReservationId int = dbo.getClientReservation('cmp2')

	exec cancelDayReservation
		@ReservationId = @testReservationId,
		@conferenceName = 'Conference1',
		@date = '2015-10-01'

	declare @ActualNumOfDaySlotsFilled int = (select SlotsFilled from Day where 
		DayId = dbo.getConferenceDayId('Conference1', '2015-10-01'))
	exec tSQLt.AssertEquals 10, @ActualNumOfDaySlotsFilled
end 
go

if object_id('[calculateTriggersTest].[testWorkshopSlotsFilledAfterWorkshopReservatinonCancelShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testWorkshopSlotsFilledAfterWorkshopReservatinonCancelShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testWorkshopSlotsFilledAfterWorkshopReservatinonCancelShouldSUCCESS] as begin

	declare @testReservationId int = dbo.getClientReservation('cmp1')

	exec cancelWorkshopReservation
		@reservationId = @testReservationId,
		@conferenceName = 'Conference1',
		@workshopName = 'Workshop1',
		@date = '2015-10-01',
		@startTime = '8:00:00'

	declare @ActualNumOfWorkshopSlotsFilled int = (select SlotsFilled 
		from WorkshopInstance WI
		inner join WorkshopType WT on WI.WorkshopTypeID = WT.WorkshopTypeID
		where WT.Name = 'Workshop1' and WI.DayID = dbo.getConferenceDayId('Conference1', '2015-10-01')
	)

	exec tSQLt.AssertEquals 0, @ActualNumOfWorkshopSlotsFilled
end 
go

--exec tSQLt.Run '[calculateTriggersTest].[testReservationPriceAfterDayReservationChangeShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testReservationPriceAfterDayReservationChangeShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testReservationPriceAfterDayReservationChangeShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testReservationPriceAfterDayReservationChangeShouldSUCCESS] as begin

	declare @testDayReservationId int = dbo.getClientReservation('cmp2')

	exec changeDayReservationNumbers
		@reservationId = @testDayReservationId,
		@conferenceName = 'Conference1',
		@date = '2015-10-01',
		@newNumberOfParticipants = 12,
		@newNumberOfStudentDiscounts = 4

	declare @ActualReservationPrice int = (select Price from Reservation where ReservationId = @testDayReservationId)

	exec tSQLt.AssertEquals 1000, @ActualReservationPrice
end 
go

--exec tSQLt.Run '[calculateTriggersTest].[testReservationPriceAfterWorkshopReservationChangeShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testReservationPriceAfterWorkshopReservationChangeShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testReservationPriceAfterWorkshopReservationChangeShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testReservationPriceAfterWorkshopReservationChangeShouldSUCCESS] as begin

	declare @testReservationId int = dbo.getClientReservation('cmp1')

	exec changeWorkshopReservationNumbers
		@reservationId = @testReservationId,
		@conferenceName = 'Conference1',
		@workshopName = 'Workshop1',
		@date = '2015-10-01',
		@startTime = '8:00:00',
		@newNumberOfParticipants = 12,
		@newNumberOfStudentDiscounts = 4


	declare @ActualReservationPrice int = (select Price from Reservation where ReservationId = @testReservationId)

	exec tSQLt.AssertEquals 1900, @ActualReservationPrice
end 
go

--exec tSQLt.Run '[calculateTriggersTest].[testPastReservationCountAfterReservationCancelShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testPastReservationCountAfterReservationCancelShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testPastReservationCountAfterReservationCancelShouldSUCCESS]
go

create procedure [calculateTriggersTest].testPastReservationCountAfterReservationCancelShouldSUCCESS as begin

	declare @testDayReservationId int = dbo.getClientReservation('cmp2')

	exec cancelReservationForClient
		@ReservationID = @testDayReservationId

	declare @PastReservationCount int = (select PastReservationCount from Client where Login = 'cmp2')

	exec tSQLt.AssertEquals 0, @PastReservationCount
end

--exec tSQLt.Run '[calculateTriggersTest].[testTotalMoneySpentAfterReservationCancelShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testTotalMoneySpentAfterReservationCancelShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testTotalMoneySpentAfterReservationCancelShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testTotalMoneySpentAfterReservationCancelShouldSUCCESS] as begin

	declare @testReservationId int = dbo.getClientReservation('cmp2')

	exec changeDayReservationNumbers
		@reservationId = @testReservationId,
		@conferenceName = 'Conference1',
		@date = '2015-10-01',
		@newNumberOfParticipants = 12,
		@newNumberOfStudentDiscounts = 4

	exec addPayment
		@ReservationId = @testReservationId,
		@payment = 500

	exec cancelReservationForClient
		@ReservationId = @testReservationId

	declare @TotalMoneySpent int = (select TotalMoneySpent from Client where Login = 'cmp2')

	exec tSQLt.AssertEquals 0, @TotalMoneySpent
end













--exec tSQLt.Run '[calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountShouldSUCCESS] as begin
	declare @testReservationId int;

	exec addNewReservation
		@Login = 'cmp3',
		@ReservationTime = '2015-09-02',
		@ReservationId = @testReservationId output

	exec addEarlyBirdDiscount
		@ConferenceName = 'Conference1',
		@StartTime = '2015-09-01 23:59:59.99',
		@EndTime = '2015-09-10 23:59:59.99',
		@Discount = 0.9


	exec dbo.addDayReservationForCompany
		@ReservationId = @testReservationId,
		@ConferenceName = 'Conference1',
		@Date = '2015-10-02',
		@NumberOfParticipants = 10,
		@NumberOfStudentDiscounts = 0

	declare @ActualReservationPrice int = (select Price from Reservation where ReservationId=@testReservationId)
	exec tSQLt.AssertEquals 100, @ActualReservationPrice
end


--exec tSQLt.Run '[calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountStudentsCheckShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountStudentsCheckShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountStudentsCheckShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountStudentsCheckShouldSUCCESS] as begin
	declare @testReservationId int;

	exec addNewReservation
		@Login = 'cmp3',
		@ReservationTime = '2015-09-02',
		@ReservationId = @testReservationId output

	exec addEarlyBirdDiscount
		@ConferenceName = 'Conference1',
		@StartTime = '2015-09-01 23:59:59.99',
		@EndTime = '2015-09-10 23:59:59.99',
		@Discount = 0.2

	exec dbo.addDayReservationForCompany
		@ReservationId = @testReservationId,
		@ConferenceName = 'Conference1',
		@Date = '2015-10-02',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 1

	declare @ActualReservationPrice int = (select Price from Reservation where ReservationId=@testReservationId)
	exec tSQLt.AssertEquals 120, @ActualReservationPrice
end


--exec tSQLt.Run '[calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountSumGreaterThanOneShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountSumGreaterThanOneShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountSumGreaterThanOneShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountSumGreaterThanOneShouldSUCCESS] as begin
	declare @testReservationId int;

	exec addNewReservation
		@Login = 'cmp3',
		@ReservationTime = '2015-09-02',
		@ReservationId = @testReservationId output

	exec addEarlyBirdDiscount
		@ConferenceName = 'Conference1',
		@StartTime = '2015-09-01 23:59:59.99',
		@EndTime = '2015-09-10 23:59:59.99',
		@Discount = 0.9

	exec dbo.addDayReservationForCompany
		@ReservationId = @testReservationId,
		@ConferenceName = 'Conference1',
		@Date = '2015-10-02',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 1

	declare @ActualReservationPrice int = (select Price from Reservation where ReservationId=@testReservationId)
	exec tSQLt.AssertEquals 15, @ActualReservationPrice
end

--exec tSQLt.Run '[calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountEqualOneThanOneShouldSUCCESS]' go
if object_id('[calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountEqualOneThanOneShouldSUCCESS]') is not null 
drop procedure [calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountEqualOneThanOneShouldSUCCESS]
go

create procedure [calculateTriggersTest].[testReservationPriceWithEarlyBirdDiscountEqualOneThanOneShouldSUCCESS] as begin
	declare @testReservationId int;

	exec addNewReservation
		@Login = 'cmp3',
		@ReservationTime = '2015-09-02',
		@ReservationId = @testReservationId output

	exec addEarlyBirdDiscount
		@ConferenceName = 'Conference1',
		@StartTime = '2015-09-01 23:59:59.99',
		@EndTime = '2015-09-10 23:59:59.99',
		@Discount = 1.0

	exec dbo.addDayReservationForCompany
		@ReservationId = @testReservationId,
		@ConferenceName = 'Conference1',
		@Date = '2015-10-02',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 1

	declare @ActualReservationPrice int = (select Price from Reservation where ReservationId=@testReservationId)
	exec tSQLt.AssertEquals 0, @ActualReservationPrice
end