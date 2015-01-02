use pachuta_a

IF OBJECT_ID('comingConferences') IS NOT NULL
drop view comingConferences
GO

CREATE VIEW comingConferences
AS
	select distinct Conference.ConferenceId, Name as 'Nazwa konferencji', 
	Venue as 'Lokalizacja', 
	(select top 1 Date from Day where Day.ConferenceID = Conference.ConferenceID) as 'Data rozpoczêcia' 
	from Conference inner join Day on Day.ConferenceID = Conference.ConferenceID
	where Date > GETDATE()
GO

IF OBJECT_ID('comingEvents') IS NOT NULL
drop view comingEvents
GO

CREATE VIEW comingEvents
AS
	select distinct C.ConferenceId, C.Name as 'Nazwa konferencji', 
	Venue as 'Miejsce konferencji', 
	Date as 'Data',
	WT.Name as 'Nazwa warsztatu',
	Location as 'Miejsce warsztatu'
	from Conference C inner join Day D on D.ConferenceID = C.ConferenceID
	inner join WorkshopInstance WI on D.DayID = WI.DayID
	inner join WorkshopType WT on WT.WorkshopTypeID = WI.WorkshopTypeID
	where Date > GETDATE()
GO

IF OBJECT_ID('mostValuableClients') IS NOT NULL
drop view mostValuableClients
GO

CREATE VIEW mostValuableClients
AS
	select top 10 T.ClientId as 'Identyfikator', T.CompanyName as 'Nazwa klienta', T.TotalMoneySpent as 'Wyda³ ³¹cznie' from
	(select C.ClientId, CP.CompanyName, C.TotalMoneySpent
	from Client C 
	inner join Company CP on C.ClientID = CP.ClientID
	union
	select top 10 C.ClientId, P.FirstName + ' ' + P.LastName, C.TotalMoneySpent
	from Client C
	inner join PersonClient PC on PC.ClientID = C.ClientID
	inner join Person P on P.PersonID = PC.PersonID
	order by C.TotalMoneySpent DESC) as T
GO

IF OBJECT_ID('clientsWithDebt') IS NOT NULL
drop view clientsWithDebt
GO

CREATE VIEW clientsWithDebt
AS
	SELECT  C.ClientID as 'Numer klienta',
	CompanyName as 'Nazwa', 
	sum(Price) as 'Do zap³aty', 
	sum(Paid) as 'Zap³acono', 
	sum(Paid) - sum(Price) as 'Saldo'
	from Company C
	inner join Reservation R on C.ClientId = R.ClientId
	group by C.ClientID, C.CompanyName
	having sum(Paid) - sum(Price) < 0
	union
	SELECT PC.ClientID,
	P.LastName + ' ' + P.FirstName as 'Nazwa',
	sum(Price) as 'Do zap³aty',
	sum(Paid) as 'Zap³acono', 
	sum(Paid) - sum(Price) as 'Saldo'
	from Person P
	inner join PersonClient PC on P.PersonID = PC.ClientID
	inner join Reservation R on R.ClientID = PC.ClientID
	group by PC.ClientID, P.LastName + ' ' + P.FirstName
	having sum(Paid) - sum(Price) < 0
GO 

IF OBJECT_ID('conferenceParticipants') IS NOT NULL
drop function conferenceParticipants
GO

CREATE FUNCTION conferenceParticipants(@conferenceId int)
RETURNS TABLE
AS
RETURN 
(
	select distinct P.PersonId, P.FirstName as 'Imie', P.LastName as 'Nazwisko'
	from Person P where exists 
	(
		select DRD.DayReservationDetailsID from DayReservationDetails DRD
		inner join DayReservation DR on DR.DayReservationID = DRD.DayReservationID
		inner join Day D on DR.DayID = D.DayID and D.ConferenceID = @conferenceId
		where DRD.PersonID = P.PersonId 
	)
)
GO

IF OBJECT_ID('workshopParticipants') IS NOT NULL
drop function workshopParticipants
GO

CREATE FUNCTION workshopParticipants(@workshopInstanceId int)
RETURNS TABLE
AS
RETURN 
(
	select distinct P.PersonId, P.FirstName as 'Imie', P.LastName as 'Nazwisko'
	from Person P where exists 
	(
		select DRD.DayReservationDetailsID from DayReservationDetails DRD
		inner join WorkshopReservationDetails WRD on WRD.DayReservationDetailsID = DRD.DayReservationDetailsID
		inner join WorkshopReservation WR on WRD.WorkshopReservationID = WR.WorkshopReservationID 
		and WorkshopInstanceID = @workshopInstanceId 
		where DRD.PersonID = P.PersonID
	)
)
GO
