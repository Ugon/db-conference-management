use pachuta_a
IF OBJECT_ID('addDayReservation') IS NOT NULL
DROP PROCEDURE addDayReservation
GO

IF OBJECT_ID('addWorkshopReservation') IS NOT NULL
DROP PROCEDURE addWorkshopReservation
GO

CREATE PROCEDURE addDayReservation
  @ConferenceName varchar(50),
  @Date date,
  @ClientLogin varchar(50),
  @NumberOfParticipants int,
  @NumberOfStudentDiscounts int
AS
BEGIN
  SET NOCOUNT ON;
  declare @dayId int;
  declare @clientId int;
  declare @discount float;
  declare @toPay int;
  declare @conferenceId int;
  declare @reservationTime datetime;
  declare @emptySlots int;
  declare @dayPrice int;
  declare @reservationId int;

  set @reservationTime = (select GETDATE())

  set @conferenceId = (select ConferenceId from Conference
    where Name = @ConferenceName)

  set @dayId = (select DayId from Day
    where ConferenceId = @conferenceId
    and Date = @Date)

  set @clientId = (select ClientId from Client where
    Login = @ClientLogin)

  set @discount = (select Discount from EarlyBirdDiscount
    where ConferenceId = @ConferenceId
    and StartTime<=@reservationTime and EndTime>=@reservationTime)
    
  set @emptySlots = (select Capacity - SlotsFilled from Day where DayID = @dayId)
  
  if @emptySlots > @NumberOfParticipants
  begin
	set @dayPrice = (select DayPrice from Conference where ConferenceID = @conferenceId)
	set @toPay = (@NumberOfParticipants - @NumberOfStudentDiscounts)*@dayPrice +
		@NumberOfStudentDiscounts*@dayPrice*(1 - @discount) 
		
	insert into Reservation(ClientID, ReservationTime, Price)
		values(@clientId, @reservationTime, @toPay)
	
	set @reservationId = SCOPE_IDENTITY();
	
	insert into DayReservation(DayID,NumberOfParticipants,NumberOfStudentDiscounts,ReservationID)
		values(@dayId, @NumberOfParticipants, @NumberOfStudentDiscounts, @reservationId)
		
  end
  --tu bedzie else z jakims errorem, ale jeszcze nie wiem jak to zrobic
  
END
GO

CREATE PROCEDURE addWorkshopReservation
	@ConferenceName varchar(50),
	@WorkshopName varchar(50),
	@Date date,
	@ClientLogin varchar(50),
	@NumberOfParticipants int,
	@NumberOfStudentDiscounts int
AS
BEGIN
	SET NOCOUNT ON;
	
	declare @freeSlots int;
	declare @dayId int;
	declare @workshopInstanceId int;
	declare @discount float;
	declare @reservationId int;
	declare @dayReservationId int;
	
	set @dayId = (select DayId from Day where Date = @Date 
		and ConferenceId = (select ConferenceID from Conference where Name = @ConferenceName))
		
	set @workshopInstanceId = (select WorkshopInstanceId from WorkshopInstance 
		where DayID = @dayId and WorkshopTypeID = (select WorkshopTypeID from WorkshopType where Name = @WorkshopName))
		
	set @freeSlots = (select Capacity from Day where DayID = @dayId) - (select SlotsFilled from WorkshopInstance
		where WorkshopInstanceID = @workshopInstanceId)
		
	if @freeSlots >= @NumberOfParticipants
	begin
		--tu bedzie dodawanie do workshopReservation i update Reservation
	end
	--i else jak wyzej
END
GO