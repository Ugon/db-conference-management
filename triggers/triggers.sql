use pachuta_a
go

if object_id('calculateDaySlotsFilled') is not null
drop trigger calculateDaySlotsFilled
go

if object_id('calculateWorkshopSlotsFilled') is not null
drop trigger calculateWorkshopSlotsFilled
go

if object_id('checkSlotsCapacityInWorkshopInstance') is not null
drop trigger checkSlotsCapacityInWorkshopInstance
go

if object_id('checkThatClientWorkchopReservationsDoNotOverlap') is not null
drop trigger checkThatClientWorkchopReservationsDoNotOverlap
go

create trigger calculateDaySlotsFilled on Reservation after insert, update as
declare @Count int
select @Count = count(*) from [Day] as d inner join DayReservaionDetails as drd on d.DayID = drd.DayID inner join Reservation as r on drd.ReservationID = r.ReservaitionID where r.Cancelled = 0
insert into [Day](SlotsFilled) values (@Count)
go

create trigger calculateWorkshopSlotsFilled on Reservation after insert, update as
declare @Count int
select @count = count(*) from workshopInstance as wi inner join WorkshopReservationDetails as wrd on wi.WorkshopInstanceID = wrd.WorkshopInstanceID inner join Reservation as r on wrd.ReservationID = r.ReservationID where cancelled = 0
insert into WorkshopInstance(SlotsFilled) values (@Count)
go

create trigger checkSlotsCapacityInWorkshopInstance on WorkshopInstance after insert, update as
if (select wi.SlotsFilled from WorkshopInstance as wi inner join inserted as i on wi.WorkshopInstanceID = i.WorkshopInstanceID)
> (select wt.Capacity from WorkshopType as wt inner join WorkshopInstance as wi on wt.WorkshopTypeID = wi.WorkshopTypeID inner join inserted as i on i.WorkshopInstanceID = wi.WorkshopInstanceID)
begin
raiserror('Workshop capacity limit exceeded', 16, 1)
rollback transaction
return
end
go

create trigger checkThatClientWorkchopReservationsDoNotOverlap on WorkshopReservationDetails after insert, update as
if exists (select * from
(select wrd.WorkshopInstanceID as wiID, wi.StartTime as st, wi.EndTime as et from WorkshopReservationDetails as wrd inner join reservation as r on r.ReservationID = wrd.ReservationID
	inner join inserted as i on i.ReservationID = r.ReservationID inner join WorkshopInstance as wi on wi.WorkshopInstanceID = wrd.WorkshopInstanceID) as t1
inner join
(select wrd.WorkshopInstanceID as wiID, wi.StartTime as st, wi.EndTime as et from WorkshopReservationDetails as wrd inner join reservation as r on r.ReservationID = wrd.ReservationID
	inner join inserted as i on i.ReservationID = r.ReservationID inner join WorkshopInstance as wi on wi.WorkshopInstanceID = wrd.WorkshopInstanceID) as t2
on t1.wiID != t2.wiID where (t1.st < t2.et and t2.et < t1.et) or (t1.st < t2.st and t2.st < t1.et))
begin
raiserror('Overlaping workshop reservation', 16, 1)
rollback transaction
return
end
go