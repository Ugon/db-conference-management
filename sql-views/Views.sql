use pachuta_a

IF OBJECT_ID('AllConferences') IS NOT NULL
drop view AllConferences
GO

CREATE VIEW AllConferences
AS
	select distinct Name,
	(select top 1 Date from Day where Day.ConferenceID = C.ConferenceID order by Date ASC) as 'StartDate',
	(1-isnull(EBD.Discount, 0)) * C.DayPrice as 'CurrentPrice',
	(select count(*) from Day where Day.ConferenceID = C.ConferenceID) as 'NumberOfDays',
	C.StudentDiscount 'StudentDiscount',
	Venue, Country, City, Street, PostalCode
	from Conference C inner join Day D on D.ConferenceID = C.ConferenceID
		inner join Address A on A.AddressID = C.AddressID
		left outer join EarlyBirdDiscount as EBD on c.ConferenceID = EBD.ConferenceID and EBD.StartTime <= GETDATE() and GETDATE() <= EBD.EndTime
GO


IF OBJECT_ID('FutureConferences') IS NOT NULL
drop view FutureConferences
GO

CREATE VIEW FutureConferences
AS
	select * from allConferences as ac
	where StartDate > GETDATE()
GO

IF OBJECT_ID('DaysOfAllConferences') IS NOT NULL
drop view DaysOfAllConferences
GO

CREATE VIEW DaysOfAllConferences
AS
	select Name, Date, Capacity, SlotsFilled
	from Conference C
	inner join Day D on C.ConferenceID = D.ConferenceID
GO

IF OBJECT_ID('DaysOfFutureConferences') IS NOT NULL
drop view DaysOfFutureConferences
GO

CREATE VIEW DaysOfFutureConferences
AS
	select Name, Date, (Capacity - SlotsFilled) as 'SlotsLeft'
	from Conference C
	inner join Day D on C.ConferenceID = D.ConferenceID
	where D.Date >= GETDATE()
GO

IF OBJECT_ID('EarlyBirdDiscountInformation') IS NOT NULL
drop view EarlyBirdDiscountInformation
GO

CREATE VIEW EarlyBirdDiscountInformation
AS
	select Name, StartTime, EndTime, Discount
	from Conference C
	inner join EarlyBirdDiscount EBD
	on EBD.ConferenceID = C.ConferenceID
GO

IF OBJECT_ID('WorkshopsOfFutureConferences') IS NOT NULL
drop view WorkshopsOfFutureConferences
GO

CREATE VIEW WorkshopsOfFutureConferences
AS
	select C.Name as 'ConferenceName', 
	WT.Name as 'WorkshopName', D.Date, WI.StartTime, 
	WI.EndTime, WT.Price, WI.Location,
	(WT.Capacity - WI.SlotsFilled) as 'SlotsLeft'
	from WorkshopInstance WI 
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
	inner join Day D on WI.DayID = D.DayID
	inner join Conference C on C.ConferenceID = D.ConferenceID
	where D.Date >= GETDATE()
GO

IF OBJECT_ID('WorkshopsOfAllConferences') IS NOT NULL
drop view WorkshopsOfAllConferences
GO

CREATE VIEW WorkshopsOfAllConferences
AS
	select C.Name as 'ConferenceName', 
	WT.Name as 'WorkshopName', D.Date, WI.StartTime, 
	WI.EndTime, WT.Price, WI.Location,
	WT.Capacity, WI.SlotsFilled
	from WorkshopInstance WI 
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
	inner join Day D on WI.DayID = D.DayID
	inner join Conference C on C.ConferenceID = D.ConferenceID
GO

IF OBJECT_ID('AllReservations') IS NOT NULL
drop view AllReservations
GO

CREATE VIEW AllReservations
AS
	select ReservationID, Login, ReservationTime, Price, Paid,
	CASE WHEN Cancelled = 1 THEN 'Yes' ELSE 'No' END AS Cancelled
	from Reservation R
	inner join Client C on C.ClientID = R.ClientID
GO

IF OBJECT_ID('PendingReservations') IS NOT NULL
drop view PendingReservations
GO

CREATE VIEW PendingReservations
AS
	select ReservationID, Login, ReservationTime, Price, Paid,
	CASE WHEN Cancelled = 1 THEN 'Yes' ELSE 'No' END AS Cancelled,
	(
		CONVERT(VARCHAR(5),datediff(ss,  GETDATE(), DATEADD(day,7,ReservationTime))/86400) + 'd ' +
		CONVERT(VARCHAR(2),((datediff(ss,DATEADD(day,7,ReservationTime),GETDATE())%86400) / 3600))  + 'h ' + 
		CONVERT(VARCHAR(2),(datediff(ss,DATEADD(day,7,ReservationTime),GETDATE()) / 60) % 60)  + 'm'
	) as 'TimeLeft'
	from Reservation R
	inner join Client C on C.ClientID = R.ClientID
	where Paid < Price and Cancelled = 0
GO

IF OBJECT_ID('UnpaidReservations') IS NOT NULL
drop view UnpaidReservations
GO

CREATE VIEW UnpaidReservations
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
		and Cancelled = 0
GO

IF OBJECT_ID('BadgesForConferenceParticipants') IS NOT NULL 
drop function BadgesForConferenceParticipants
GO
CREATE function BadgesForConferenceParticipants(@ConferenceName varchar(200)) returns table
AS return
	select distinct FirstName, LastName,
	P.Mail, CompanyName
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join DayReservation DR on DR.DayReservationID = DRD.DayReservationID
	inner join Day D on D.DayID = DR.DayID 
	inner join Conference CF on CF.ConferenceID = D.DayID
	inner join Reservation R on DR.ReservationID = R.ReservationID
	inner join Client C on C.ClientID = R.ClientID
	left join Company CP on CP.ClientID = C.ClientID
	where cf.Name = @ConferenceName
GO

IF OBJECT_ID('ConferenceParticipants') IS NOT NULL
drop function ConferenceParticipants
GO

CREATE FUNCTION ConferenceParticipants(@conferenceName varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select distinct FirstName, LastName, P.Mail, CompanyName
	from Person P
	inner join DayReservationDetails as DRD on DRD.PersonID = P.PersonID
	inner join DayReservation as DR on DR.DayReservationID = DRD.DayReservationID
	inner join [Day] as d on d.DayID = dr.DayID
	inner join Conference as c on c.ConferenceID = d.ConferenceID
	inner join Reservation as R on DR.ReservationID = R.ReservationID
	inner join Client as Cl on Cl.ClientID = R.ClientID
	left join Company as CP on Cl.ClientID = CP.ClientID
	where c.Name = @conferenceName
)
GO

IF OBJECT_ID('DayParticipants') IS NOT NULL
drop function DayParticipants
GO

CREATE FUNCTION DayParticipants(@conferenceName varchar(200), @date date)
RETURNS TABLE
AS
RETURN 
(
	select FirstName, LastName, P.Mail, CompanyName
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join DayReservation DR on DR.DayReservationID = DRD.DayReservationID
	inner join Reservation R on DR.ReservationID = R.ReservationID
	inner join Client C on C.ClientID = R.ClientID
	left join Company CP on C.ClientID = CP.ClientID
	where DR.DayID = dbo.getConferenceDayId(@conferenceName, @date)
)
GO

IF OBJECT_ID('WorkshopParticipants') IS NOT NULL
drop function WorkshopParticipants
GO

CREATE FUNCTION WorkshopParticipants(@conferenceName varchar(200), @date date, @workshopName varchar(200), @startTime time)
RETURNS TABLE
AS
RETURN 
(
	select FirstName, LastName, P.Mail
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join WorkshopReservationDetails WRD on WRD.DayReservationDetailsID = DRD.DayReservationDetailsID
	inner join WorkshopReservation WR on WR.WorkshopInstanceID = WRD.WorkshopReservationID
	inner join WorkshopInstance WI on WI.WorkshopInstanceID = WR.WorkshopInstanceID
		and WI.DayID = dbo.getConferenceDayId(@conferenceName, @date)
	inner join WorkshopType WT on WI.WorkshopTypeID = WT.WorkshopTypeID
	where WI.StartTime = @startTime and WT.Name = @workshopName
)
GO

IF OBJECT_ID('PersonClients') IS NOT NULL
drop view PersonClients
GO

CREATE VIEW PersonClients
AS
	select FirstName, LastName, Login, Mail, Phone, BankAccount, Country, City, Street, PostalCode from Person P
	inner join PersonClient PC on PC.PersonID = P.PersonID
	inner join Client C on C.ClientID = PC.ClientID
	inner join Address A on A.AddressID = C.AddressID
GO

IF OBJECT_ID('CompanyClients') IS NOT NULL
drop view CompanyClients
GO

CREATE VIEW CompanyClients
AS
	select CompanyName,Login, Mail, Phone, BankAccount, 
	Country, City, Street, PostalCode 
	from Company CP
	inner join Client C on C.ClientID = CP.ClientID
	inner join Address A on C.AddressID = A.AddressID
GO

IF OBJECT_ID('MoneySpentStatisticsForCompanyClients') IS NOT NULL
drop view MoneySpentStatisticsForCompanyClients
GO

CREATE VIEW MoneySpentStatisticsForCompanyClients
AS
	select CompanyName, Login, TotalMoneySpent, PastReservationCount 
	from Company CP
	inner join Client C on CP.ClientID = C.ClientID
GO

IF OBJECT_ID('MoneySpentStatisticsForPersonClients') IS NOT NULL
drop view MoneySpentStatisticsForPersonClients
GO

CREATE VIEW MoneySpentStatisticsForPersonClients
AS
	select FirstName, LastName, Login, TotalMoneySpent, PastReservationCount 
	from Person P
	inner join PersonClient PC on PC.PersonID = P.PersonID
	inner join Client C on PC.ClientID = C.ClientID
GO

IF OBJECT_ID('AllClientReservations') IS NOT NULL
drop function AllClientReservations
GO

CREATE FUNCTION AllClientReservations(@login varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select ReservationID, ReservationTime, Price, Paid, 
	CASE WHEN Cancelled = 1 THEN 'Yes' ELSE 'No' END AS Cancelled 
	from Reservation R
	inner join Client as C on c.ClientID = R.ClientID
	where C.Login = @Login
)
GO

IF OBJECT_ID('ReservationDaysForPersonClient') IS NOT NULL
drop function ReservationDaysForPersonClient
GO

CREATE FUNCTION ReservationDaysForPersonClient(@reservationID int)
RETURNS TABLE
AS
RETURN 
(
	select CF.Name as 'ConferenceName', Date, Student
	from DayReservation DR 
	inner join Day D on DR.DayID = D.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	inner join DayReservationDetails DRD on DRD.DayReservationID = DR.DayReservationID
	where DR.ReservationID = @reservationID
)
GO

IF OBJECT_ID('ReservationWorkshopsForPersonClient') IS NOT NULL
drop function ReservationWorkshopsForPersonClient
GO

CREATE FUNCTION ReservationWorkshopsForPersonClient(@reservationId int)
RETURNS TABLE
AS
RETURN 
(
	select CF.Name as 'ConferenceName', WT.Name as 'WorkshopName', Date, StartTime, EndTime
	from DayReservation DR
	inner join WorkshopReservation WR on WR.DayReservationID = DR.DayReservationID
	inner join WorkshopInstance WI on WR.WorkshopInstanceID = WI.WorkshopInstanceID
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
	inner join Day D on D.DayID = WI.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
 	where DR.ReservationID = @reservationId
)
GO

IF OBJECT_ID('ReservationDaysForCompanyClient') IS NOT NULL
drop function ReservationDaysForCompanyClient
GO

CREATE FUNCTION ReservationDaysForCompanyClient(@reservationID int)
RETURNS TABLE
AS
RETURN 
(
	select CF.Name, Date, NumberOfParticipants, NumberOfStudentDiscounts
	from DayReservation DR  
	inner join Day D on D.DayID = DR.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	where DR.ReservationID = @reservationID
)
GO

IF OBJECT_ID('ReservationWorkshopsForCompanyClient') IS NOT NULL
drop function ReservationWorkshopsForCompanyClient
GO

CREATE FUNCTION ReservationWorkshopsForCompanyClient(@reservationID int)
RETURNS TABLE
AS
RETURN 
(
	select CF.Name as 'ConferenceName', Date, WT.Name as 'WorkshopName', StartTime, EndTime,
		WR.NumberOfParticipants, WR.NumberOfStudentDiscounts
	from DayReservation DR
	inner join Day D on D.DayID = DR.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	inner join WorkshopReservation WR on WR.DayReservationID = DR.DayReservationID
	inner join WorkshopInstance WI on WI.WorkshopInstanceID = WR.WorkshopInstanceID
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
	where DR.ReservationID = @reservationID
)
GO

IF OBJECT_ID('ReservationDayDetailsForCompanyClient') IS NOT NULL
drop function ReservationDayDetailsForCompanyClient
GO

CREATE FUNCTION ReservationDayDetailsForCompanyClient(@ReservationID int, @conferenceName varchar(200), @date date)
RETURNS TABLE
AS
RETURN 
(
	select FirstName, LastName, Mail, Student
	from Day D
	inner join DayReservation DR on DR.DayID = D.DayID
	inner join DayReservationDetails DRD on DRD.DayReservationID = DR.DayReservationID
	inner join Person P on P.PersonID = DRD.PersonID
	where D.DayID = dbo.getConferenceDayId(@conferenceName, @date) and DR.ReservationID = @ReservationID
)
GO

IF OBJECT_ID('ReservationWorkshopDetailsForCompanyClient') IS NOT NULL
drop function ReservationWorkshopDetailsForCompanyClient
GO

CREATE FUNCTION ReservationWorkshopDetailsForCompanyClient(@ReservationID int, @conferenceName varchar(200), @date date,
	@workshopName varchar(200), @startTime time)
RETURNS TABLE
AS
RETURN 
(
	select FirstName, LastName, Mail, Student
	from WorkshopReservationDetails as wrd
	inner join WorkshopReservation as wr on wrd.WorkshopReservationID = wr.WorkshopReservationID
	inner join DayReservation as dr on dr.DayReservationID = wr.DayReservationID
	inner join WorkshopInstance as wi on wi.WorkshopInstanceID = wr.WorkshopInstanceID
	inner join WorkshopType as wt on wt.WorkshopTypeID = wi.WorkshopTypeID
	inner join DayReservationDetails as drd on wrd.DayReservationDetailsID = drd.DayReservationDetailsID
	inner join Person as p on drd.PersonID = p.PersonID
	where dr.ReservationID = @ReservationID and wi.StartTime = @startTime and wt.Name = @workshopName
	and wi.DayID = dbo.getConferenceDayId(@conferenceName, @date) 
)
GO

IF OBJECT_ID('ReservationFreeDaySlots') IS NOT NULL
drop function ReservationFreeDaySlots
GO

CREATE FUNCTION ReservationFreeDaySlots(@ReservationID int)
RETURNS TABLE
AS
RETURN 
(
	select c.Name as 'ConferenceName', d.Date,
	dr.NumberOfParticipants - (select count(*) from DayReservationDetails as drd where drd.DayReservationID = dr.DayReservationID) as 'SlotsToFill', 
	dr.NumberOfStudentDiscounts - (select count(*) from DayReservationDetails as drd where drd.DayReservationID = dr.DayReservationID and drd.Student = 1) as 'StudentDiscountsLeft'
	from DayReservation as dr
	inner join [Day] as d on dr.DayID = d.DayID
	inner join Conference as c on c.ConferenceID = d.ConferenceID
	where dr.ReservationID = @ReservationID
)
GO

IF OBJECT_ID('ReservationFreeWorkshopSlots') IS NOT NULL
drop function ReservationFreeWorkshopSlots
GO

CREATE FUNCTION ReservationFreeWorkshopSlots(@ReservationID int)
RETURNS TABLE
AS
RETURN 
(
	select c.Name as 'ConferenceName', d.Date, wt.Name as 'WorkshopName', wi.StartTime,
	wr.NumberOfParticipants - (select count(*) from WorkshopReservationDetails as wrd where wrd.WorkshopReservationID = wr.WorkshopReservationID) as 'SlotsToFill', 
	wr.NumberOfStudentDiscounts - (select count(*) from WorkshopReservationDetails as wrd
		inner join DayReservationDetails as drd on drd.DayReservationDetailsID = wrd.DayReservationDetailsID
		where wrd.WorkshopReservationID = wr.WorkshopReservationID and drd.Student = 1) as 'StudentDiscountsLeft'
	from WorkshopReservation as wr
	inner join DayReservation as dr on dr.DayReservationID = wr.DayReservationID
	inner join WorkshopInstance as wi on wi.WorkshopInstanceID = wr.WorkshopInstanceID
	inner join WorkshopType as wt on wt.WorkshopTypeID = wi.WorkshopTypeID
	inner join [Day] as d on dr.DayID = d.DayID
	inner join Conference as c on d.ConferenceID = c.ConferenceID
	where dr.ReservationID = @ReservationID
)
GO


IF OBJECT_ID('ConferenceListForParticipant') IS NOT NULL
drop function ConferenceListForParticipant
GO

CREATE FUNCTION ConferenceListForParticipant(@mail varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select distinct	CF.Name as 'ConferenceName', Venue, Country, City, Street, PostalCode
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join DayReservation DR on DRD.DayReservationID = DR.DayReservationID
	inner join Day D on D.DayID = DR.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	inner join Address A on CF.AddressID = A.AddressID 
	where P.Mail = @mail
)
GO

IF OBJECT_ID('DayListForParticipant') IS NOT NULL
drop function DayListForParticipant
GO

CREATE FUNCTION DayListForParticipant(@mail varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select CF.Name as 'ConferenceName', Date
	from Person P
	inner join DayReservationDetails DRD on DRD.PersonID = P.PersonID
	inner join DayReservation DR on DRD.DayReservationID = DR.DayReservationID
	inner join Day D on D.DayID = DR.DayID
	inner join Conference CF on CF.ConferenceID = D.ConferenceID
	where P.Mail = @mail 
)
GO

IF OBJECT_ID('WorkshopListForParticipant') IS NOT NULL
drop function WorkshopListForParticipant
GO

CREATE FUNCTION WorkshopListForParticipant(@mail varchar(200))
RETURNS TABLE
AS
RETURN 
(
	select CF.Name as 'ConferenceName', Date, WT.Name as 'WorkshopName', StartTime, EndTime, Location
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



