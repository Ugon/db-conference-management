--exec tSQLt.RunTestClass [PersonReservationTest]
use test_db
go

exec tSQLt.DropClass 'PersonReservationTest' 
go
exec tSQLt.NewTestClass 'PersonReservationTest'
go

if object_id('[PersonReservationTest].[setup]') is not null drop procedure [PersonReservationTest].[setup]
go
create procedure [PersonReservationTest].[setup] as begin
--setup creates a conference with 2 days and 2 workshops - one in each day
--person client makes a reservation for one slot of day 1 and one slot of workshop 1

	declare @ReservationID int

	exec addConference
		@Name = 'TestConference1',
		@Venue = 'TestVenue1',
		@DayPrice = 200,
		@StudentDiscount = 0.1,
		@Street = 'TestStreet1',
		@PostalCode = '00-001',
		@City = 'TestCity1',
		@Country = 'TestCoutry1'

	exec addWorkshopType
		@WorkshopTypeName = 'TestWorkshopType1',
		@Capacity = 1,
		@Price = 20

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@Capacity = 1

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@Capacity = 1

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType1',
		@ConferenceName = 'TestConference1',
		@StartTime = '8:00:00',
		@EndTime = '9:00:00',
		@WorkshopDate = '2000-01-01',
		@Location = 'TestLocation1'

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType1',
		@ConferenceName = 'TestConference1',
		@StartTime = '8:00:00',
		@EndTime = '9:00:00',
		@WorkshopDate = '2000-01-02',
		@Location = 'TestLocation1'

	exec addClientPerson
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Street = 'TestStreet2',
		@PostalCode = '00-002',
		@City = 'TestCity2',
		@Country = 'TestCoutry2',
		@Login = 'TestLogin1',
		@Password = 'TestPassword',
		@Mail = 'TestMail1@mail.com',
		@Phone = '123 456 789',
		@BankAccount = '00 1111 2222 3333 4444 5555 6666'

	exec addNewReservation
		@Login = 'TestLogin1',
		@ReservationID = @ReservationID output

	exec addDayReservationForPerson
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

	exec addWorkshopReservationForPerson
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-01',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

end
go


--exec tSQLt.Run '[PersonReservationTest].[testDataCreationProcess]'
if object_id('[PersonReservationTest].[testDataCreationProcess]') is not null drop procedure [PersonReservationTest].[testDataCreationProcess]
go
create procedure [PersonReservationTest].[testDataCreationProcess] as begin

	declare @ActualNumOfConferences int = (select count(*) from Conference)
	exec tSQLt.AssertEquals 1, @ActualNumOfConferences
	
	declare @ActualNumOfDays int = (select count(*) from Day)
	exec tSQLt.AssertEquals 2, @ActualNumOfDays
	
	declare @ActualNumOfWorkshops int = (select count(*) from WorkshopInstance)
	exec tSQLt.AssertEquals 2, @ActualNumOfWorkshops
	
	declare @ActualNumOfDayReservations int = (select count(*) from DayReservation)
	exec tSQLt.AssertEquals 1, @ActualNumOfDayReservations
	
	declare @ActualNumOfWorkshopReservations int = (select count(*) from WorkshopReservation)
	exec tSQLt.AssertEquals 1, @ActualNumOfWorkshopReservations
	
	declare @ActualNumOfDayReservationDetails int = (select count(*) from DayReservationDetails)
	exec tSQLt.AssertEquals 1, @ActualNumOfDayReservationDetails

	declare @ActualNumOfWorkshopReservationdetails int = (select count(*) from WorkshopReservationDetails)
	exec tSQLt.AssertEquals 1, @ActualNumOfWorkshopReservationdetails
	
	declare @ActualNumOfClients int = (select count(*) from Client)
	exec tSQLt.AssertEquals 1, @ActualNumOfClients

	declare @ActualNumOfPeople int = (select count(*) from Person)
	exec tSQLt.AssertEquals 1, @ActualNumOfPeople

	declare @ActualNumOfCompanies int = (select count(*) from Company)
	exec tSQLt.AssertEquals 0, @ActualNumOfCompanies

end 
go


--exec tSQLt.Run '[PersonReservationTest].[testRegisteringPersonForWorkshopWithoutRegisteringForDayShouldFAIL]'
if object_id('[PersonReservationTest].[testRegisteringPersonForWorkshopWithoutRegisteringForDayShouldFAIL]') is not null drop procedure [PersonReservationTest].[testRegisteringPersonForWorkshopWithoutRegisteringForDayShouldFAIL]
go
create procedure [PersonReservationTest].[testRegisteringPersonForWorkshopWithoutRegisteringForDayShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec tSQLt.ExpectException --there is no DayReservation.DayReservationID to reference
	exec addWorkshopReservationForPerson
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

end


--exec tSQLt.Run '[PersonReservationTest].[testRemovingPersonFromDayWhenHeIsRegisteredForWorkshopShouldFAIL]'
if object_id('[PersonReservationTest].[testRemovingPersonFromDayWhenHeIsRegisteredForWorkshopShouldFAIL]') is not null drop procedure [PersonReservationTest].[testRemovingPersonFromDayWhenHeIsRegisteredForWorkshopShouldFAIL]
go
create procedure [PersonReservationTest].[testRemovingPersonFromDayWhenHeIsRegisteredForWorkshopShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec tSQLt.ExpectException --WorkshopReservationDetails.DayReservationDetailsID would reference non existing DayReservationDetails entry
	exec removeDayReservationForPerson
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@Mail = 'TestMail1@mail.com'

end