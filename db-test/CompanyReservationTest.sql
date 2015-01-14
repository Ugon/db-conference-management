--exec tSQLt.RunTestClass [CompanyReservationTest]
use test_db
go

exec tSQLt.DropClass 'CompanyReservationTest' 
go
exec tSQLt.NewTestClass 'CompanyReservationTest'
go

if object_id('[CompanyReservationTest].[setup]') is not null drop procedure [CompanyReservationTest].[setup]
go
create procedure [CompanyReservationTest].[setup] as begin
--setup creates a conference with 2 days and 2 workshops - one in each day
--company client makes a reservation for one slot of day 1 and one slot of workshop 1
--company client fills reserved slot with an employee

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

	exec addClientCompany
		@CompanyName = 'TestCompany1',
		@Street = 'TestStreet2',
		@PostalCode = '00-002',
		@City = 'TestCity2',
		@Country = 'TestCoutry2',
		@Login = 'TestLogin1',
		@Password = 'TestPassword',
		@Mail = 'Test1@Mail.ru',
		@Phone = '123 456 789',
		@BankAccount = '00 1111 2222 3333 4444 5555 6666'

	exec addNewReservation
		@Login = 'TestLogin1',
		@ReservationID = @ReservationID output

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-01',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec addWorkshopReservationDetailsForCompany
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


--exec tSQLt.Run '[CompanyReservationTest].[testDataCreationProcess]'
if object_id('[CompanyReservationTest].[testDataCreationProcess]') is not null drop procedure [CompanyReservationTest].[testDataCreationProcess]
go
create procedure [CompanyReservationTest].[testDataCreationProcess] as begin

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
	exec tSQLt.AssertEquals 1, @ActualNumOfCompanies

end 
go


--exec tSQLt.Run '[CompanyReservationTest].[testRegisterPersonForWorkshopInDayHeIsNotRegisteredForShouldFAIL]'
if object_id('[CompanyReservationTest].[testRegisterPersonForWorkshopInDayHeIsNotRegisteredForShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testRegisterPersonForWorkshopInDayHeIsNotRegisteredForShouldFAIL]
go
create procedure [CompanyReservationTest].[testRegisterPersonForWorkshopInDayHeIsNotRegisteredForShouldFAIL] as begin
--company client makes a reservation for one slot of day 2 and one slot of workshop 2
--company client tries to add an employee for workshop without adding him for day first - THIS IS EXPECTED TO FAIL

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec tSQLt.ExpectException
	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

end
go


--exec tSQLt.Run '[CompanyReservationTest].[testRegisterPersonForWorkshopInDayHeIsRegisteredForShouldSUCCEED]'
if object_id('[CompanyReservationTest].[testRegisterPersonForWorkshopInDayHeIsRegisteredForShouldSUCCEED]') is not null drop procedure [CompanyReservationTest].[testRegisterPersonForWorkshopInDayHeIsRegisteredForShouldSUCCEED]
go
create procedure [CompanyReservationTest].[testRegisterPersonForWorkshopInDayHeIsRegisteredForShouldSUCCEED] as begin
--company client makes a reservation for one slot of day 2 and one slot of workshop 2
--company client adds an employee for day 2 and then for workshop 2 - THIS IS EXPECTED TO SUCCEED

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec tSQLt.ExpectNoException
	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

end
go



--exec tSQLt.Run '[CompanyReservationTest].[testRegisterPersonForOverlapingWorkshopsShouldFAIL]'
if object_id('[CompanyReservationTest].[testRegisterPersonForOverlapingWorkshopsShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testRegisterPersonForOverlapingWorkshopsShouldFAIL]
go
create procedure [CompanyReservationTest].[testRegisterPersonForOverlapingWorkshopsShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType1',
		@ConferenceName = 'TestConference1',
		@StartTime = '8:30:00',
		@EndTime = '9:30:00',
		@WorkshopDate = '2000-01-02',
		@Location = 'TestLocation1'

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:30:00',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0
	
	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'
		
	exec tSQLt.ExpectException @ExpectedMessage = 'Overlaping workshop reservation'
	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:30:00',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'
	
end
go


--exec tSQLt.Run '[CompanyReservationTest].[testMakingAReservationForMoreParticipantsThanParticipantsInDayShouldFAIL]'
if object_id('[CompanyReservationTest].[testMakingAReservationForMoreParticipantsThanParticipantsInDayShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testMakingAReservationForMoreParticipantsThanParticipantsInDayShouldFAIL]
go
create procedure [CompanyReservationTest].[testMakingAReservationForMoreParticipantsThanParticipantsInDayShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)
	
	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@Capacity = 2

	exec addWorkshopType
		@WorkshopTypeName = 'TestWorkshopType2',
		@Capacity = 2,
		@Price = 20

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType2',
		@ConferenceName = 'TestConference1',
		@StartTime = '8:00:00',
		@EndTime = '9:00:00',
		@WorkshopDate = '2000-01-03',
		@Location = 'TestLocation1'

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec tSQLt.ExpectException @ExpectedMessage = 'WorkshopReservation NumberOfParticipants is greater than DayReservation NumberOfParticipants'
	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType2',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

end
go


--exec tSQLt.Run '[CompanyReservationTest].[testMakingAReservationForMoreStudentsThanStudentsInDayShouldFAIL]'
if object_id('[CompanyReservationTest].[testMakingAReservationForMoreStudentsThanStudentsInDayShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testMakingAReservationForMoreStudentsThanStudentsInDayShouldFAIL]
go
create procedure [CompanyReservationTest].[testMakingAReservationForMoreStudentsThanStudentsInDayShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)
	
	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@Capacity = 2

	exec addWorkshopType
		@WorkshopTypeName = 'TestWorkshopType2',
		@Capacity = 2,
		@Price = 20

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType2',
		@ConferenceName = 'TestConference1',
		@StartTime = '8:00:00',
		@EndTime = '9:00:00',
		@WorkshopDate = '2000-01-03',
		@Location = 'TestLocation1'

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 1

	exec tSQLt.ExpectException @ExpectedMessage = 'WorkshopReservation NumberOfStudentDiscount is greater than DayReservation NumberOfStudentDiscount'
	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType2',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 2

end
go

--exec tSQLt.Run '[CompanyReservationTest].[testAddingMorePeopleToDayThanInReservationShouldFAIL]'
if object_id('[CompanyReservationTest].[testAddingMorePeopleToDayThanInReservationShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testAddingMorePeopleToDayThanInReservationShouldFAIL]
go
create procedure [CompanyReservationTest].[testAddingMorePeopleToDayThanInReservationShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec tSQLt.ExpectException @ExpectedMessage = 'Number of registered participants for day exceeds DayReservation NumberOfParticipants limit'
	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com'

end
go


--exec tSQLt.Run '[CompanyReservationTest].[testAddingMoreStudentsToDayThanInReservationShouldFAIL]'
if object_id('[CompanyReservationTest].[testAddingMoreStudentsToDayThanInReservationShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testAddingMoreStudentsToDayThanInReservationShouldFAIL]
go
create procedure [CompanyReservationTest].[testAddingMoreStudentsToDayThanInReservationShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec tSQLt.ExpectException @ExpectedMessage = 'Number of registered students for day exceeds DayReservation NumberOfStudentDiscounts limit'
	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com',
		@IndexNumber = '123457'

end
go


--exec tSQLt.Run '[CompanyReservationTest].[testAddingMorePeopleToWorkshopThanInReservationShouldFAIL]'
if object_id('[CompanyReservationTest].[testAddingMorePeopleToWorkshopThanInReservationShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testAddingMorePeopleToWorkshopThanInReservationShouldFAIL]
go
create procedure [CompanyReservationTest].[testAddingMorePeopleToWorkshopThanInReservationShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@Capacity = 2

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType1',
		@ConferenceName = 'TestConference1',
		@StartTime = '8:00:00',
		@EndTime = '9:00:00',
		@WorkshopDate = '2000-01-03',
		@Location = 'TestLocation1'

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com'

	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

	exec tSQLt.ExpectException @ExpectedMessage = 'Number of registered participants for workshop exceeds WorkshopReservation NumberOfParticipants limit'
	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com'

end
go


--exec tSQLt.Run '[CompanyReservationTest].[testAddingMoreStudentsToWorkshopThanInReservationShouldFAIL]'
if object_id('[CompanyReservationTest].[testAddingMoreStudentsToWorkshopThanInReservationShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testAddingMoreStudentsToWorkshopThanInReservationShouldFAIL]
go
create procedure [CompanyReservationTest].[testAddingMoreStudentsToWorkshopThanInReservationShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 1

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-02',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com',
		@IndexNumber = '123456'

	exec tSQLt.ExpectException @ExpectedMessage = 'Number of registered students for workshop exceeds WorkshopReservation NumberOfStudentDiscounts limit'
	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-02',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com',
		@IndexNumber = '123456'

end
go


--exec tSQLt.Run '[CompanyReservationTest].[testModifyingReservationAfterPaymentShouldFAIL]'
if object_id('[CompanyReservationTest].[testModifyingReservationAfterPaymentShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testModifyingReservationAfterPaymentShouldFAIL]
go
create procedure [CompanyReservationTest].[testModifyingReservationAfterPaymentShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@Capacity = 2

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 0

	exec addPayment
		@ReservationID = @ReservationID,
		@Payment = 200

	exec tSQLt.ExpectException @ExpectedMessage = 'Attempting to modify a reservation that was already paid for'
	exec changeNumberOfParticipantsDay
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NewNumberOfParticipants = 2

end


--exec tSQLt.Run '[CompanyReservationTest].[testReducingNumberOfDayParticipantsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]'
if object_id('[CompanyReservationTest].[testReducingNumberOfDayParticipantsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testReducingNumberOfDayParticipantsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]
go
create procedure [CompanyReservationTest].[testReducingNumberOfDayParticipantsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@Capacity = 2

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com'

	exec tSQLt.ExpectException @ExpectedMessage = 'Insterted NumberOfParticipants can not accomodate all currently enlisted participants'
	exec changeNumberOfParticipantsDay
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NewNumberOfParticipants = 1

end


--exec tSQLt.Run '[CompanyReservationTest].[testReducingNumberOfDayStudentsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]'
if object_id('[CompanyReservationTest].[testReducingNumberOfDayStudentsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testReducingNumberOfDayStudentsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]
go
create procedure [CompanyReservationTest].[testReducingNumberOfDayStudentsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@Capacity = 1

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 1

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com',
		@IndexNumber = '123457'

	exec tSQLt.ExpectException @ExpectedMessage = 'Insterted NumberOfStudentDiscounts can not accomodate all currently enlisted students'
	exec changeNumberOfStudentsDay
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NewNumberOfStudentDiscounts = 0

end


--exec tSQLt.Run '[CompanyReservationTest].[testReducingNumberOfWorkshopParticipantsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]'
if object_id('[CompanyReservationTest].[testReducingNumberOfWorkshopParticipantsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testReducingNumberOfWorkshopParticipantsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]
go
create procedure [CompanyReservationTest].[testReducingNumberOfWorkshopParticipantsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@Capacity = 2

	exec addWorkshopType
		@WorkshopTypeName = 'TestWorkshopType2',
		@Capacity = 2,
		@Price = 20

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType2',
		@ConferenceName = 'TestConference1', 
		@StartTime = '8:00:00',
		@EndTime = '9:00:00',
		@WorkshopDate = '2000-01-03',
		@Location = 'TestLocation1'

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com'

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType2',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType2',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName1',
		@LastName = 'TestLastName1',
		@Mail = 'TestMail1@mail.com'

	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType2',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com'

	exec tSQLt.ExpectException @ExpectedMessage = 'Insterted NumberOfParticipants can not accomodate all currently enlisted participants'
	exec changeNumberOfParticipantsWorkshop
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType2',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@NewNumberOfParticipants = 1

end


--exec tSQLt.Run '[CompanyReservationTest].[testReducingNumberOfWorkshopStudentsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]'
if object_id('[CompanyReservationTest].[testReducingNumberOfWorkshopStudentsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testReducingNumberOfWorkshopStudentsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL]
go
create procedure [CompanyReservationTest].[testReducingNumberOfWorkshopStudentsSoThatItCanNoLongerAccomodateAllEnlistedPeopleShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@Capacity = 1

	exec addWorkshopType
		@WorkshopTypeName = 'TestWorkshopType2',
		@Capacity = 1,
		@Price = 20

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType2',
		@ConferenceName = 'TestConference1', 
		@StartTime = '8:00:00',
		@EndTime = '9:00:00',
		@WorkshopDate = '2000-01-03',
		@Location = 'TestLocation1'

	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 1

	exec addDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-03',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com',
		@IndexNumber = 123458

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType2',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 1,
		@NumberOfStudentDiscounts = 1

	exec addWorkshopReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType2',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@FirstName = 'TestFirstName2',
		@LastName = 'TestLastName2',
		@Mail = 'TestMail2@mail.com',
		@IndexNumber = 123458

	exec tSQLt.ExpectException @ExpectedMessage = 'Insterted NumberOfStudentDiscounts can not accomodate all currently enlisted students'
	exec changeNumberOfStudentsWorkshop
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType2',
		@Date = '2000-01-03',
		@StartTime = '8:00:00',
		@NewNumberOfStudentDiscounts = 0

end


--exec tSQLt.Run '[CompanyReservationTest].[testRemovingSomeoneFromDayWhenHeIsRegisteredForWorkshopShouldFAIL]'
if object_id('[CompanyReservationTest].[testRemovingSomeoneFromDayWhenHeIsRegisteredForWorkshopShouldFAIL]') is not null drop procedure [CompanyReservationTest].[testRemovingSomeoneFromDayWhenHeIsRegisteredForWorkshopShouldFAIL]
go
create procedure [CompanyReservationTest].[testRemovingSomeoneFromDayWhenHeIsRegisteredForWorkshopShouldFAIL] as begin

	declare @ReservationID int = (select ReservationID from Reservation)

	exec tSQLt.ExpectException --WorkshopReservationDetails.DayReservationDetailsID would reference non existing DayReservationDetails entry
	exec removeDayReservationDetailsForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@Mail = 'TestMail1@mail.com'

end