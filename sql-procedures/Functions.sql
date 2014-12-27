use pachuta_a

IF OBJECT_ID('getConferenceId') IS NOT NULL
DROP FUNCTION getConferenceId
GO
IF OBJECT_ID('getConferenceDayId') IS NOT NULL
DROP FUNCTION getConferenceDayId
GO


CREATE FUNCTION getConferenceId
(
	@Name varchar(50)
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

CREATE FUNCTION getConferenceDayId
(
	@ConferenceName varchar(50),
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