use test_db
go

exec tSQLt.DropClass 'OtherTests' 
go
exec tSQLt.NewTestClass 'OtherTests'
go


--exec tSQLt.Run '[OtherTests].[testAddingOverlapingEarlyBirdDiscountsShouldFAIL]'
if object_id('[OtherTests].[testAddingOverlapingEarlyBirdDiscountsShouldFAIL]') is not null drop procedure [OtherTests].[testAddingOverlapingEarlyBirdDiscountsShouldFAIL]
go
create procedure [OtherTests].[testAddingOverlapingEarlyBirdDiscountsShouldFAIL] as begin

	exec addConference
		@Name = 'TestConference1',
		@Venue = 'TestVenue1',
		@DayPrice = 200,
		@StudentDiscount = 0.1,
		@Street = 'TestStreet1',
		@PostalCode = '00-001',
		@City = 'TestCity1',
		@Country = 'TestCoutry1'

		exec addEarlyBirdDiscount
			@ConferenceName = 'TestConference1',
			@StartTime = '2010-01-01 8:00:00',
			@EndTime = '2010-02-01 8:00:00',
			@Discount = 0.1

		EXEC tSQLt.ExpectException @eXPECTEDmESSAGE = 'Overlaping EarlyBirdDiscounts'
		exec addEarlyBirdDiscount
			@ConferenceName = 'TestConference1',
			@StartTime = '2010-01-15 8:00:00',
			@EndTime = '2010-02-15 8:00:00',
			@Discount = 0.1

end
go


--exec tSQLt.Run '[OtherTests].[testExceedingDayCapacityShouldFAIL]'
if object_id('[OtherTests].[testExceedingDayCapacityShouldFAIL]') is not null drop procedure [OtherTests].[testExceedingDayCapacityShouldFAIL]
go
create procedure [OtherTests].[testExceedingDayCapacityShouldFAIL] as begin

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

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@Capacity = 1

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

	exec tSQLt.ExpectException --check on Day table Capacity >= SlotsFiled
	exec addDayReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

end


--exec tSQLt.Run '[OtherTests].[testExceedingWorkshopCapacityShouldFAIL]'
if object_id('[OtherTests].[testExceedingWorkshopCapacityShouldFAIL]') is not null drop procedure [OtherTests].[testExceedingWorkshopCapacityShouldFAIL]
go
create procedure [OtherTests].[testExceedingWorkshopCapacityShouldFAIL] as begin

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
		@Capacity = 2

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType1',
		@ConferenceName = 'TestConference1',
		@StartTime = '8:00:00',
		@EndTime = '9:00:00',
		@WorkshopDate = '2000-01-01',
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
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

	exec tSQLT.ExpectException @ExpectedMessage = 'Workshop SlotsFilled exceeds Capacity'
	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-01',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

end


--exec tSQLt.Run '[OtherTests].[testReducingDayCapacitySoThatItCanNoLongerAccomodateAllParticipantsShouldFAIL]'
if object_id('[OtherTests].[testReducingDayCapacitySoThatItCanNoLongerAccomodateAllParticipantsShouldFAIL]') is not null drop procedure [OtherTests].[testReducingDayCapacitySoThatItCanNoLongerAccomodateAllParticipantsShouldFAIL]
go
create procedure [OtherTests].[testReducingDayCapacitySoThatItCanNoLongerAccomodateAllParticipantsShouldFAIL] as begin

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

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@Capacity = 2

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
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

	exec tSQLt.ExpectException @ExpectedMessage = 'New Day Capacity can not accomodate all registered participants'
	--decreasing day capacity to 1 goes here.

end


--exec tSQLt.Run '[OtherTests].[testReducingWorkshopCapacitySoThatItCanNoLongerAccomodateAllParticipantsShouldFAIL]'
if object_id('[OtherTests].[testReducingWorkshopCapacitySoThatItCanNoLongerAccomodateAllParticipantsShouldFAIL]') is not null drop procedure [OtherTests].[testReducingWorkshopCapacitySoThatItCanNoLongerAccomodateAllParticipantsShouldFAIL]
go
create procedure [OtherTests].[testReducingWorkshopCapacitySoThatItCanNoLongerAccomodateAllParticipantsShouldFAIL] as begin

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
		@Capacity = 2,
		@Price = 20

	exec addConferenceDay
		@ConferenceName = 'TestConference1',
		@Date = '2000-01-01',
		@Capacity = 2

	exec addWorkshopInstance
		@WorkshopTypeName = 'TestWorkshopType1',
		@ConferenceName = 'TestConference1',
		@StartTime = '8:00:00',
		@EndTime = '9:00:00',
		@WorkshopDate = '2000-01-01',
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
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

	exec addWorkshopReservationForCompany
		@ReservationID = @ReservationID,
		@ConferenceName = 'TestConference1',
		@WorkshopName = 'TestWorkshopType1',
		@Date = '2000-01-01',
		@StartTime = '8:00:00',
		@NumberOfParticipants = 2,
		@NumberOfStudentDiscounts = 0

	exec tSQLt.ExpectException @ExpectedMessage = 'New Workshop Capacity can not accomodate all registered participants'
	--decreasing workshop capacity to 1 goes here.

end