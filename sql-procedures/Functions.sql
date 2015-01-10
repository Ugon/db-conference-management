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
	RETURN (select DayReservationId from DayReservation 
	where ReservationID = @reservationId and DayID = dbo.getConferenceDayId(@conferenceName, @date))
END
GO