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
	where Paid < Price
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