use pachuta_a

exec addConference
	@Name = 'Confitura',
	@Venue = 'Jakas duza sala',
	@DayPrice = 1234.4324421342,
	@StudentDiscount = 0.2,
	@Street = 'Armii Krajowej',
	@PostalCode = '33-234',
	@City = 'Krakuff',
	@Country = 'Poland'
go

exec addConferenceDay
	@ConferenceName = 'Confitura',
	@Date = '2012-01-13',
	@Capacity = 150
go

exec addWorkshopType
	@WorkshopTypeName = 'Bzdury',
	@Capacity = 13,
	@Price = 123
go

exec addWorkshopInstance
	@WorkshopTypeName = 'Bzdury',
	@ConferenceName = 'Confitura',
	@StartTime = '07:25:35:123',
	@EndTime = '08:25:35:123',
	@WorkshopDate = '2012-01-13',
	@Location = 'SALA 8'
go

exec addClientCompanyIfNotExists
	@CompanyName = 'Bullshit solutions',
	@Street = 'Czarnowiejska',
	@PostalCode = '12-123',
	@City = 'Krakow',
	@Country = 'Poland',
	@Login = 'SBSOL8',
	@Password = 'ala123',
	@Mail = 'bssol@gmail.com',
	@Phone = '123 456 798',
	@BankAccount = '11 1111 1111 1111 1111 1111 1111'

exec addClientPersonIfNotExists
	@FirstName = 'Tytus',
	@LastName = 'Tytusowski',
	@Street = 'Rolnicza',
	@PostalCode = '00-666',
	@City = 'Warsaw',
	@Country = 'Poland',
	@Login = 'TYTTYT4',
	@Password = 'ala 124',
	@Mail = 'tytus@tytusowski.com',
	@Phone = '222 333 444',
	@BankAccount = '11 1111 1111 1111 1111 1111 1112',
	@IndexNumber = null

exec addClientPersonIfNotExists
	@FirstName = 'Tytusa',
	@LastName = 'Tytusowskia',
	@Street = 'Rolniczaa',
	@PostalCode = '00-667',
	@City = 'Warsawa',
	@Country = 'Polanda',
	@Login = 'TYTTYT4a',
	@Password = 'ala 124a',
	@Mail = 'tytus@tytusowski.coma',
	@Phone = '222 333 445',
	@BankAccount = '11 1111 1111 1111 1111 1111 1113',
	@IndexNumber = '123456'


	select * from Client
	select * from Company
	select * from person
	select * from [day]
	select * from conference
	
select * from client
select * from reservation

declare @dupa int

exec addNewReservation
	@Login = 'TYTTYT4',
	@ReservationTime = '2000-01-01',
	@ReservationId = @Dupa output