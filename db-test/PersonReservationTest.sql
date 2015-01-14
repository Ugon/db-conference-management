--exec tSQLt.RunTestClass [PersonReservationTest]
use test_db
go

exec tSQLt.DropClass 'PersonReservationTest' 
go
exec tSQLt.NewTestClass 'PersonReservationTest'
go

if object_id('[CompanyReservationTest].[setup]') is not null drop procedure [CompanyReservationTest].[setup]
go
create procedure [CompanyReservationTest].[setup] as begin
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