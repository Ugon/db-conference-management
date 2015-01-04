use pachuta_a

IF OBJECT_ID('comingConferences') IS NOT NULL
drop view comingConferences
GO

CREATE VIEW comingConferences
AS
	select distinct Name,
	(select top 1 Date from Day where Day.ConferenceID = C.ConferenceID order by Date ASC) as 'Start date',
	(select top 1 T.D from
		(select (1-Discount)*C.DayPrice as D
		from EarlyBirdDiscount EBD
		where StartTime<=GETDATE() and EndTime>=GETDATE() and EBD.ConferenceID = C.ConferenceID
		union
		select C.DayPrice as D
		)
	as T order by T.D ASC )
	as 'Current Price',
	 
	(select count(*) from Day where Day.ConferenceID = C.ConferenceID) as 'Number of days',
	CONVERT(VARCHAR(50), 100*StudentDiscount,128) + '%' as 'Student Discount',
	 Venue, Country, Street, PostalCode
	from Conference C inner join Day D on D.ConferenceID = C.ConferenceID
		inner join Address A on A.AddressID = C.AddressID
	where Date > GETDATE()
GO

IF OBJECT_ID('allConferences') IS NOT NULL
drop view allConferences
GO

CREATE VIEW allConferences
AS
	select distinct Name,
	(select top 1 Date from Day where Day.ConferenceID = C.ConferenceID order by Date ASC) as 'Start date',
	(select top 1 T.D from
		(select (1-Discount)*C.DayPrice as D
		from EarlyBirdDiscount EBD
		where StartTime<=GETDATE() and EndTime>=GETDATE() and EBD.ConferenceID = C.ConferenceID
		union
		select C.DayPrice as D
		)
	as T order by T.D ASC )
	as 'Current Price',
	(select count(*) from Day where Day.ConferenceID = C.ConferenceID) as 'Number of days',
	CONVERT (VARCHAR(50), 100*StudentDiscount,128) + '%' as 'Student Discount',
	 Venue, Country, Street, PostalCode
	from Conference C inner join Day D on D.ConferenceID = C.ConferenceID
		inner join Address A on A.AddressID = C.AddressID
GO


IF OBJECT_ID('allConferenceDays') IS NOT NULL
drop view allConferenceDays
GO

CREATE VIEW allConferenceDays
AS
	select Name, Date, (Capacity - SlotsFilled) as 'Slots left'
	from Conference C
	inner join Day D on C.ConferenceID = D.ConferenceID
GO

IF OBJECT_ID('allConferenceDaysOrganizer') IS NOT NULL
drop view allConferenceDaysOrganizer
GO

CREATE VIEW allConferenceDaysOrganizer
AS
	select Name, Date, Capacity, SlotsFilled
	from Conference C
	inner join Day D on C.ConferenceID = D.ConferenceID
GO

IF OBJECT_ID('earlyBirdDiscountInfo') IS NOT NULL
drop view earlyBirdDiscountInfo
GO

CREATE VIEW earlyBirdDiscountInfo
AS
	select Name, StartTime, EndTime, 
	CONVERT (VARCHAR(50), 100*Discount,128) + '%' as 'Discount'
	from Conference C
	inner join EarlyBirdDiscount EBD
	on EBD.ConferenceID = C.ConferenceID
GO

IF OBJECT_ID('allWorkshopInfo') IS NOT NULL
drop view allWorkshopInfo
GO

CREATE VIEW allWorkshopInfo
AS
	select C.Name as 'Conference Name', 
	WT.Name as 'Workshop Name', D.Date, WI.StartTime, 
	WI.EndTime, WT.Price, WI.Location,
	(WT.Capacity - WI.SlotsFilled) as 'Slots left'
	from WorkshopInstance WI 
	inner join WorkshopType WT
	on WT.WorkshopTypeID = WI.WorkshopTypeID
	inner join Day D on WI.DayID = D.DayID
	inner join Conference C on C.ConferenceID = D.ConferenceID
GO

IF OBJECT_ID('allWorkshopInfoOrganizer') IS NOT NULL
drop view allWorkshopInfoOrganizer
GO

CREATE VIEW allWorkshopInfoOrganizer
AS
	select C.Name as 'Conference Name', 
	WT.Name as 'Workshop Name', D.Date, WI.StartTime, 
	WI.EndTime, WT.Price, WI.Location,
	WT.Capacity, (WT.Capacity - WI.SlotsFilled) as 'Slots left'
	from WorkshopInstance WI 
	inner join WorkshopType WT
	on WT.WorkshopTypeID = WI.WorkshopTypeID
	inner join Day D on WI.DayID = D.DayID
	inner join Conference C on C.ConferenceID = D.ConferenceID
GO

IF OBJECT_ID('allReservation') IS NOT NULL
drop view allReservation
GO

CREATE VIEW allReservation
AS
	select ReservationID, Login, ReservationTime, Price, Paid,
	CASE WHEN Cancelled = 1 THEN 'Yes' ELSE 'No' END AS Cancelled
	from Reservation R
	inner join Client C on C.ClientID = R.ClientID
GO

IF OBJECT_ID('unpaidReservations') IS NOT NULL
drop view unpaidReservations
GO

CREATE VIEW unpaidReservations
AS
	select ReservationID, Login, ReservationTime, Price, Paid,
	CASE WHEN Cancelled = 1 THEN 'Yes' ELSE 'No' END AS Cancelled,
	(
		CONVERT(VARCHAR(5),datediff(ss,  GETDATE(), DATEADD(day,7,ReservationTime))/86400) + 'd ' +
		CONVERT(VARCHAR(2),((datediff(ss,DATEADD(day,7,ReservationTime),GETDATE())%86400) / 3600))  + 'h ' + 
		CONVERT(VARCHAR(2),(datediff(ss,DATEADD(day,7,ReservationTime),GETDATE()) / 60) % 60)  + 'm'
	) as 'Time left'
	from Reservation R
	inner join Client C on C.ClientID = R.ClientID
	where Paid < Price and Cancelled = 'No'
GO

IF OBJECT_ID('unpaidAfterWeek') IS NOT NULL
drop view unpaidAfterWeek
GO

CREATE VIEW unpaidAfterWeek
AS
	select ReservationID, Login, ReservationTime,
	CASE WHEN Cancelled = 1 THEN 'Yes' ELSE 'No' END AS Cancelled,
	(
		CONVERT(VARCHAR(5), datediff(ss,DATEADD(day,7,ReservationTime), GETDATE())/86400) + 'd ' +
		CONVERT(VARCHAR(2),((datediff(ss,DATEADD(day,7,ReservationTime),GETDATE())%86400) / 3600))  + 'h ' + 
		CONVERT(VARCHAR(2),(datediff(ss,DATEADD(day,7,ReservationTime),GETDATE()) / 60) % 60)  + 'm'
	) as 'After payment time',
	Price, Paid
	from Reservation R
	inner join Client C on C.ClientID = R.ClientID
	where Paid < Price and datediff(ss,GETDATE(), DATEADD(day,7,ReservationTime) ) < 0
		and Cancelled = 'No'
GO

IF OBJECT_ID('badgesForAllParticipants') IS NOT NULL
drop view badgesForAllParticipants
GO

CREATE VIEW badgesForAllParticipants
AS
	select distinct CF.Name as 'Conference Name', FirstName, LastName,
	P.Mail, ISNULL(CompanyName, ' ') as 'Company Name'
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join DayReservation DR on DR.DayReservationID = DRD.DayReservationID
	inner join Day D on D.DayID = DR.DayID 
	inner join Conference CF on CF.ConferenceID = D.DayID
	inner join Reservation R on DR.ReservationID = R.ReservationID
	left join Client C on C.ClientID = R.ClientID
	left join Company CP on CP.ClientID = C.ClientID
GO

IF OBJECT_ID('dayParticipants') IS NOT NULL
drop function dayParticipants
GO

CREATE FUNCTION dayParticipants(@conferenceName varchar(200), @date date)
RETURNS TABLE
AS
RETURN 
(
	select FirstName, LastName, P.Mail, ISNULL(CompanyName, ' ') as 'Company Name'
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join DayReservation DR on DR.DayReservationID = DRD.DayReservationID and DR.DayID = dbo.getConferenceDayId(@conferenceName, @date)
	inner join Reservation R on DR.ReservationID = R.ReservationID
	inner join Client C on C.ClientID = R.ClientID
	left join Company CP on C.ClientID = CP.ClientID
)
GO

IF OBJECT_ID('workshopParticipants') IS NOT NULL
drop function workshopParticipants
GO

CREATE FUNCTION workshopParticipants(@conferenceName varchar(200), @date date, @workshopName varchar(200), @startTime time)
RETURNS TABLE
AS
RETURN 
(
	select FirstName, LastName, P.Mail
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join WorkshopReservationDetails WRD on WRD.DayReservationDetailsID = DRD.DayReservationDetailsID
	inner join WorkshopReservation WR on WR.WorkshopInstanceID = WRD.WorkshopReservationID
	inner join WorkshopInstance WI on WI.WorkshopInstanceID = WR.WorkshopInstanceID and WI.StartTime = @startTime
		and WI.DayID = dbo.getConferenceDayId(@conferenceName, @date)
	inner join WorkshopType WT on WI.WorkshopTypeID = WT.WorkshopTypeID and WT.Name = @workshopName
)
GO

IF OBJECT_ID('allPersonClients') IS NOT NULL
drop view allPersonClients
GO

CREATE VIEW allPersonClients
AS
	select FirstName, LastName, Login, Mail, Phone, BankAccount, Country, City, Street, PostalCode from Person P
	inner join PersonClient PC on PC.PersonID = P.PersonID
	inner join Client C on C.ClientID = PC.ClientID
	inner join Address A on A.AddressID = C.AddressID
GO

IF OBJECT_ID('allCompanyClients') IS NOT NULL
drop view allCompanyClients
GO

CREATE VIEW allCompanyClients
AS
	select CompanyName,Login, Mail, Phone, BankAccount, 
	Country, City, Street, PostalCode 
	from Company CP
	inner join Client C on C.ClientID = CP.ClientID
	inner join Address A on C.AddressID = A.AddressID
GO

IF OBJECT_ID('moneySpentStatisticsCompany') IS NOT NULL
drop view moneySpentStatisticsCompany
GO

CREATE VIEW moneySpentStatisticsCompany
AS
	select CompanyName, Login, TotalMoneySpent, PastReservationCount 
	from Company CP
	inner join Client C on CP.ClientID = C.ClientID
GO

IF OBJECT_ID('moneySpentStatisticsPersonClient') IS NOT NULL
drop view moneySpentStatisticsPersonClient
GO

CREATE VIEW moneySpentStatisticsPersonClient
AS
	select FirstName, LastName, Login, TotalMoneySpent, PastReservationCount 
	from Person P
	inner join PersonClient PC on PC.PersonID = P.PersonID
	inner join Client C on PC.ClientID = C.ClientID
GO

IF OBJECT_ID('allClientReservations') IS NOT NULL
drop function allClientReservations
GO

CREATE FUNCTION allClientReservations(@login varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select ReservationID, ReservationTime, Price, Paid, 
	CASE WHEN Cancelled = 1 THEN 'Yes' ELSE 'No' END AS Cancelled 
	from Reservation R
	where R.ClientID = (select ClientID 
		from Client C
		where C.Login = @login
		)
)
GO

IF OBJECT_ID('personClientDaysDetails') IS NOT NULL
drop function personClientDaysDetails
GO

CREATE FUNCTION personClientDaysDetails(@login varchar(200), @reservationID int)
RETURNS TABLE
AS
RETURN 
(
	select CF.Name as 'Conference Name', Date, WT.Name as 'Workshop Name', StartTime, EndTime, Student
	from Client C 
	inner join Reservation R on R.ClientID = C.ClientID and C.Login  = @login
	inner join DayReservation DR on DR.ReservationID = R.ReservationID and R.ReservationID = @reservationID
	inner join Day D on DR.DayID = D.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	inner join WorkshopReservation WR on DR.DayReservationID = WR.DayReservationID 
	inner join WorkshopInstance WI on WI.WorkshopInstanceID = WR.WorkshopInstanceID
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
	inner join DayReservationDetails DRD on DRD.DayReservationID = DR.DayReservationID
)
GO

IF OBJECT_ID('personClientWorkshopsDetails') IS NOT NULL
drop function personClientWorkshopsDetails
GO

CREATE FUNCTION personClientWorkshopsDetails(@login varchar(200), @reservationId int)
RETURNS TABLE
AS
RETURN 
(
	select CF.Name as 'Conference Name', WT.Name as 'Workshop Name', StartTime, EndTime, Student
	from Client C
	inner join Reservation R on C.ClientID = R.ClientID and R.ReservationID = @reservationId
	inner join DayReservation DR on DR.ReservationID = R.ReservationID
	inner join DayReservationDetails DRD on DRD.DayReservationID = DR.DayReservationID
	inner join WorkshopReservation WR on WR.DayReservationID = DR.DayReservationID
	inner join WorkshopInstance WI on WR.WorkshopInstanceID = WI.WorkshopInstanceID
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
	inner join Day D on D.DayID = WI.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
 	where 
	C.Login = @login
)
GO

IF OBJECT_ID('companyClientDaysDetails') IS NOT NULL
drop function companyClientDaysDetails
GO

CREATE FUNCTION companyClientDaysDetails(@login varchar(200), @reservationID int)
RETURNS TABLE
AS
RETURN 
(
	select CF.Name, Date, NumberOfParticipants, NumberOfStudentDiscounts
	from Client C
	inner join DayReservation DR on DR.ReservationID = @reservationID
	inner join Day D on D.DayID = DR.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	where 
	C.Login = @login
)
GO

IF OBJECT_ID('companyClientWorkshopsDetails') IS NOT NULL
drop function companyClientWorkshopsDetails
GO

CREATE FUNCTION companyClientWorkshopsDetails(@login varchar(200), @reservationID int)
RETURNS TABLE
AS
RETURN 
(
	select CF.Name as 'Conference Name', Date, WT.Name as 'Workshop Name', StartTime, EndTime,
		WR.NumberOfParticipants as 'Workshop Participants', 
		WR.NumberOfStudentDiscounts as 'Workshop student discounts'
	from Client C
	inner join DayReservation DR on DR.ReservationID = @reservationID
	inner join Day D on D.DayID = DR.DayID
	inner join Conference CF on CF.ConferenceID = D.DayID
	inner join WorkshopReservation WR on WR.DayReservationID = DR.DayReservationID
	inner join WorkshopInstance WI on WI.WorkshopInstanceID = WR.WorkshopInstanceID
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
	where 
	C.Login = @login
)
GO

IF OBJECT_ID('participantsListForDay') IS NOT NULL
drop function participantsListForDay
GO

CREATE FUNCTION participantsListForDay(@conferenceName varchar(200), @date date, @login varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select FirstName, LastName, Mail, Student
	from Day D
	inner join DayReservation DR on DR.DayID = D.DayID
	inner join DayReservationDetails DRD on DRD.DayReservationID = DR.DayReservationID
	inner join Person P on P.PersonID = DRD.PersonID
	inner join Reservation R on R.ReservationID = DR.ReservationID
	inner join Client C on C.ClientID = R.ClientID
		and C.Login = @login
	where 
	D.DayID = dbo.getConferenceDayId(@conferenceName, @date)
)
GO

IF OBJECT_ID('participantsListForWorkshop') IS NOT NULL
drop function participantsListForWorkshop
GO

CREATE FUNCTION participantsListForWorkshop(@conferenceName varchar(200), @date date,
	@workshopName varchar(200), @startTime time, @login varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select FirstName, LastName, Mail, Student
	from Day D
	inner join WorkshopInstance WI on WI.DayID = D.DayID and WI.StartTime = @startTime
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID and WT.Name = @workshopName
	inner join DayReservation DR on DR.DayID = D.DayID
	inner join DayReservationDetails DRD on DRD.DayReservationID  = DR.DayReservationID
	inner join Person P on P.PersonID = DRD.PersonID  
	inner join Reservation R on R.ReservationID = DR.ReservationID
	inner join Client C on C.ClientID = R.ClientID and C.Login = @login
	where 
	D.DayID = dbo.getConferenceDayId(@conferenceName, @date)
)
GO

IF OBJECT_ID('dayToFill') IS NOT NULL
drop function dayToFill
GO

CREATE FUNCTION dayToFill(@conferenceName varchar(200), @date date, @login varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select NumberOfParticipants, NumberOfStudentDiscounts
	from Client C	
	inner join Reservation R on R.ClientID = C.ClientID
	inner join DayReservation DR on DR.ReservationID = R.ReservationID
		and DR.DayID = dbo.getConferenceDayId(@conferenceName, @date)
	where 
	C.Login = @login

)
GO

IF OBJECT_ID('workshopToFill') IS NOT NULL
drop function workshopToFill
GO

CREATE FUNCTION workshopToFill(@conferenceName varchar(200), @date date, @login varchar(200), 
	@workshopName varchar(200), @startTime time)
RETURNS TABLE
AS
RETURN 
(
	select WR.NumberOfParticipants, WR.NumberOfStudentDiscounts
	from Client C	
	inner join Reservation R on R.ClientID = C.ClientID
	inner join DayReservation DR on DR.ReservationID = R.ReservationID
		and DR.DayID = dbo.getConferenceDayId(@conferenceName, @date)
	inner join WorkshopReservation WR on WR.DayReservationID = DR.DayReservationID
	inner join WorkshopInstance WI on WI.WorkshopInstanceID = WR.WorkshopInstanceID
		and WI.DayID = DR.DayID and WI.StartTime = @startTime
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID and WT.Name = @workshopName
	where 
	C.Login = @login
)
GO


IF OBJECT_ID('conferenceListForParticipant') IS NOT NULL
drop function conferenceListForParticipant
GO

CREATE FUNCTION conferenceListForParticipant(@mail varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select distinct	CF.Name, Venue, Country, City, Street, PostalCode
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join DayReservation DR on DRD.DayReservationID = DR.DayReservationID
	inner join Day D on D.DayID = DR.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	inner join Address A on CF.AddressID = A.AddressID 
	where P.Mail = @mail
)
GO

IF OBJECT_ID('daysListForParticipant') IS NOT NULL
drop function daysListForParticipant
GO

CREATE FUNCTION daysListForParticipant(@mail varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select CF.Name, Date
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join DayReservation DR on DRD.DayReservationID = DR.DayReservationID
	inner join Day D on D.DayID = DR.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	where P.Mail = @mail 
)
GO

IF OBJECT_ID('workshopListForParticipant') IS NOT NULL
drop function workshopListForParticipant
GO

CREATE FUNCTION workshopListForParticipant(@mail varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select CF.Name as 'Conference Name', Date, WT.Name as 'Workshop Name', StartTime, EndTime, Location
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join WorkshopReservationDetails WRD on WRD.DayReservationDetailsID = DRD.DayReservationDetailsID
	inner join WorkshopReservation WR on WR.WorkshopReservationID = WRD.WorkshopReservationID
	inner join WorkshopInstance WI on WI.WorkshopInstanceID = WR.WorkshopInstanceID
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
	inner join Day D on D.DayID = WI.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	where Mail = @mail
)
GO



