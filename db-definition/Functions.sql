use pachuta_a

IF OBJECT_ID('getConferenceId') IS NOT NULL
DROP FUNCTION getConferenceId
GO

CREATE FUNCTION getConferenceId
(
	@Name varchar(200)
)
RETURNS int
AS
BEGIN
	declare @conferenceId int;
	set @conferenceId = (select ConferenceId from Conference 
		where Name = @Name)
	RETURN @conferenceId
END
GO

IF OBJECT_ID('getConferenceDayId') IS NOT NULL
DROP FUNCTION getConferenceDayId
GO

CREATE FUNCTION getConferenceDayId
(
	@ConferenceName varchar(200),
	@Date date
)
RETURNS int
AS
BEGIN
	declare @dayId int;
	declare @confNameId int;
	
	set @confNameId = (select ConferenceID from Conference where Name = @ConferenceName);
	set @dayId = (select DayId from Day where ConferenceID = @confNameId and Date = @Date);
	
	RETURN @dayId;
END
GO

IF OBJECT_ID('getDayReservationId') IS NOT NULL
DROP FUNCTION getDayReservationId
GO

CREATE Function getDayReservationId
(
	@reservationId int,
	@conferenceName varchar(200),
	@date date
)
RETURNS int
AS 
BEGIN
	RETURN (
		select DayReservationId from DayReservation 
		where ReservationID = @reservationId and DayID = dbo.getConferenceDayId(@conferenceName, @date)
	)
END
GO

IF OBJECT_ID('getWorkshopTypeId') IS NOT NULL
DROP FUNCTION getWorkshopTypeId
GO

CREATE FUNCTION getWorkshopTypeId
(
	@workshopName varchar(200)
)
RETURNS int
AS
BEGIN
	RETURN (
		select WorkshopTypeID from WorkshopType where Name = @workshopName
	)
END
GO

IF OBJECT_ID('getWorkshopInstanceId') IS NOT NULL
DROP FUNCTION getWorkshopInstanceId
GO

CREATE Function getWorkshopInstanceId
(
	@conferenceName varchar(200),
	@workshopName varchar(200),
	@date date,
	@startTime time
)
RETURNS int
AS 
BEGIN
	RETURN (
		select WorkshopInstanceID 
		from WorkshopInstance WI
		where DayID = dbo.getConferenceDayId(@conferenceName, @date)
		and StartTime = @startTime 
		and WorkshopTypeID = dbo.getWorkshopTypeId(@workshopName)
	)
END
GO

IF OBJECT_ID('getWorkshopReservationId') IS NOT NULL
DROP FUNCTION getWorkshopReservationId
GO

CREATE Function getWorkshopReservationId
(
	@reservationId int,
	@conferenceName varchar(200),
	@workshopName varchar(200),
	@date date,
	@startTime time
)
RETURNS int
AS 
BEGIN
	RETURN (
		select WorkshopReservationID
		from WorkshopReservation
		where DayReservationID = dbo.getDayReservationId(@reservationId, @conferenceName, @date)
		and WorkshopInstanceID = dbo.getWorkshopInstanceId(@conferenceName, @workshopName, @date, @startTime)
	)
END
GO