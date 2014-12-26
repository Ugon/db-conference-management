use pachuta_a
if object_id('calculateDaySlotsFilledAfterReservationCancel') is not null drop trigger calculateDaySlotsFilledAfterReservationCancel
go
if object_id('calculateWorkshopSlotsFilledAfterReservationCancel') is not null drop trigger calculateWorkshopSlotsFilledAfterReservationCancel
go
if object_id('calculateDaySlotsFilledAfterCreatingReservation') is not null drop trigger calculateDaySlotsFilledAfterCreatingReservation
go
if object_id('calculateWorkshopSlotsFilledAfterCreatingReservation') is not null drop trigger calculateWorkshopSlotsFilledAfterCreatingReservation
go
if object_id('checkThatPersonWorkshopReservationsDoNotOverlap') is not null drop trigger checkThatPersonWorkshopReservationsDoNotOverlap
go
if object_id('checkWorkshopNumberOfParticipantsInRelationToDayNumberOfParticipants') is not null drop trigger checkWorkshopNumberOfParticipantsInRelationToDayNumberOfParticipants
go
if object_id('checkWorkshopNumberOfStudentDiscountsInRelationToDaNumberOfStudentDiscounts') is not null drop trigger checkWorkshopNumberOfStudentDiscountsInRelationToDaNumberOfStudentDiscounts
go
if object_id('checkDayNumberOfStudentDiscountsInRelationToActualNumberOfStudentDayReservationDetails') is not null drop trigger checkDayNumberOfStudentDiscountsInRelationToActualNumberOfStudentDayReservationDetails
go
if object_id('checkWorkshopNumberOfStudentDiscountsInRelationToActualNumberOfStudentWorkshopReservationDetails') is not null drop trigger checkWorkshopNumberOfStudentDiscountsInRelationToActualNumberOfStudentWorkshopReservationDetails
go
if object_id('checkThatPersonRegisteredAsStudentHasIndexNumber') is not null drop trigger checkThatPersonRegisteredAsStudentHasIndexNumber
go







if object_id('calculateDaySlotsFilled') is not null drop function calculateDaySlotsFilled
go
create function calculateDaySlotsFilled(@DayID int) returns int as begin
	return (select sum(dr.NumberOfParticipants) from [Day] as d
		inner join DayReservation as dr on d.DayID = dr.DayID
		inner join Reservation as r on r.ReservationID = dr.ReservationID
		where d.DayID = @DayID and r.Cancelled = 0)
end
go

if object_id('calculateWorkshopSlotsFilled') is not null drop function calculateWorkshopSlotsFilled
go
create function calculateWorkshopSlotsFilled(@WorkshopInstanceID int) returns int as begin
	return (select sum(dr.NumberOfParticipants) from WorkshopInstance as wi
		 inner join WorkshopReservation as wr on wi.WorkshopInstanceID = wr.WorkshopInstanceID
		 inner join DayReservation as dr on dr.DayReservationID = wr.DayReservationID
		 inner join Reservation as r on r.ReservationID = dr.ReservationID
		 where wi.WorkshopInstanceID = @WorkshopInstanceID and r.Cancelled = 0)
end
go





--SlotsFilled <= Capacity enforced by constraint
create trigger calculateDaySlotsFilledAfterReservationCancel on Reservation after update as
if (select Cancelled from deleted) = 0 and (select Cancelled from inserted) = 1 begin
	declare @DayID int
	declare @DaySlotsFilled int
	declare AffectedDays cursor for select dr.DayID from DayReservation as dr inner join inserted as i on i.ReservationID = dr.ReservationID
	open AffectedDays
	fetch next from AffectedDays into @DayID
	while @@fetch_status = 0 begin
		exec @DaySlotsFilled = calculateDaySlotsFilled @DayID = @DayID
		update [Day] set SlotsFilled = @DaySlotsFilled where DayID = @DayID
	end
	close AffectedDays
	deallocate AffectedDays
end
go

--SlotsFilled <= Capacity enforced by constraint
create trigger calculateWorkshopSlotsFilledAfterReservationCancel on Reservation after update as
if (select Cancelled from deleted) = 0 and (select Cancelled from inserted) = 1 begin
	declare @WorkshopInstanceID int
	declare @WorkshopSlotsFilled int
	declare AffectedWorkshops cursor for select wr.WorkshopInstanceID from WorkshopReservation as wr inner join DayReservation as dr on wr.DayReservationID = dr.DayReservationID inner join inserted as i on i.ReservationID = dr.ReservationID
	open AffectedWorkshops
	fetch next from AffectedWorkshops into @WorkshopInstanceID
	while @@fetch_status = 0 begin
		exec @WorkshopSlotsFilled = calculateWorkshopSlotsFilled @WorkshopInstanceID = @WorkshopInstanceID
		update WorkshopInstance set SlotsFilled = @WorkshopSlotsFilled where WorkshopInstanceID = @WorkshopInstanceID
	end
	close AffectedWorkshops
	deallocate AffectedWorkshops
end
go

--SlotsFilled <= Capacity enforced by constraint
create trigger calculateDaySlotsFilledAfterCreatingReservation on DayReservation after insert as begin
	declare @DayID int = (select DayID from inserted)
	declare @NumberOfParticipants int = (select NumberOfParticipants from inserted)
	update [Day] set SlotsFilled += @NumberOfParticipants where DayID = @DayID
end
go

--SlotsFilled <= Capacity enforced by constraint
create trigger calculateWorkshopSlotsFilledAfterCreatingReservation on WorkshopReservation after insert as begin
	declare @WorkshopInstanceID int = (select WorkshopInstanceID from inserted)
	declare @NumberOfParticipants int = (select NumberOfParticipants from inserted)
	update WorkshopInstance set SlotsFilled += @NumberOfParticipants where WorkshopInstanceID = @WorkshopInstanceID
end
go

create trigger checkThatPersonWorkshopReservationsDoNotOverlap on WorkshopReservationDetails after insert as begin
	declare @PersonID int = 
		(select drd.PersonID from inserted as i
		inner join DayReservationDetails as drd on i.DayReservationDetailsID = drd.DayReservationDetailsID)
	declare @DayID int =
		(select wi.dayID from inserted as i
		inner join WorkshopReservation as wr on i.WorkshopReservationID = wr.WorkshopReservationID
		inner join WorkshopInstance as wi on wi.WorkshopInstanceID = wr.WorkshopInstanceID)
	declare @WorkshopInstances table(WorkshopInstanceID int primary key, StartTime time, EndTime time)
	insert into @WorkshopInstances (WorkshopInstanceID, StartTime, EndTime)
		select wi.WorkshopInstanceID, wi.StartTime, wi.EndTime from WorkshopReservationDetails as wrd
		inner join DayReservationDetails as drd on wrd.DayReservationDetailsID = drd.DayReservationDetailsID
		inner join WorkshopReservation as wr on wrd.WorkshopReservationID = wr.WorkshopReservationID
		inner join WorkshopInstance as wi on wr.WorkshopInstanceID = wi.WorkshopInstanceID
		where drd.PersonID = @PersonID and wi.DayID = @DayID
	if exists (select * from @WorkshopInstances as t1 inner join @WorkshopInstances as t2 on t1.WorkshopInstanceID != t2.WorkshopInstanceID
		where (t1.StartTime < t2.EndTime and t2.EndTime < t1.EndTime) or (t1.StartTime < t2.StartTime and t2.StartTime < t1.EndTime))
	begin
		raiserror('Overlaping workshop reservation', 16, 1)
		rollback transaction
		return
	end
end
go

create trigger checkWorkshopNumberOfParticipantsInRelationToDayNumberOfParticipants on WorkshopReservation after insert as
	if (select NumberOfParticipants from inserted) > (select dr.NumberOfParticipants from inserted as i inner join DayReservation as dr on i.DayReservationID = i.DayReservationID)
	begin
		raiserror('WorkshopReservation NumberOfParticipants is greater than DayReservation NumberOfParticipants', 16, 1)
		rollback transaction
		return
	end
go

create trigger checkWorkshopNumberOfStudentDiscountsInRelationToDaNumberOfStudentDiscounts on WorkshopReservation after insert as
	if (select NumberOfStudentDiscounts from inserted) > (select dr.NumberOfStudentDiscounts from inserted as i inner join DayReservation as dr on i.DayReservationID = i.DayReservationID)
	begin
		raiserror('WorkshopReservation NumberOfStudentDiscount is greater than DayReservation NumberOfStudentDiscount', 16, 1)
		rollback transaction
		return
	end
go

create trigger checkDayNumberOfStudentDiscountsInRelationToActualNumberOfStudentDayReservationDetails on DayReservationDetails after insert, update as
	if(select count(*) from DayReservationDetails as drd inner join inserted as i on i.DayReservationID = drd.DayReservationID where drd.Student = 1)
		> (select NumberOfStudentDiscounts from DayReservation as dr inner join inserted as i on dr.DayReservationID = i.DayReservationID)
		begin
	raiserror('Number of registered students for day exceeds DayReservation NumberOfStudentDiscounts limit', 16, 1)
		rollback transaction
		return
	end
go

create trigger checkWorkshopNumberOfStudentDiscountsInRelationToActualNumberOfStudentWorkshopReservationDetails on WorkshopReservationDetails after insert, update as
	if(select count(*) from WorkshopReservationDetails as wrd 
			inner join inserted as i on i.WorkshopReservationID = wrd.WorkshopReservationID
			inner join WorkshopReservation as wr on wrd.WorkshopReservationID = wr.WorkshopReservationID
			inner join DayReservationDetails as drd on drd.DayReservationDetailsID = wrd.DayReservationDetailsID
			 where drd.Student = 1)
		> (select NumberOfStudentDiscounts from WorkshopReservation as wr inner join inserted as i on wr.WorkshopReservationID = i.WorkshopReservationID)
	begin
		raiserror('Number of registered students for workshop exceeds WorkshopReservation NumberOfStudentDiscounts limit', 16, 1)
		rollback transaction
		return
	end
go

create trigger checkThatPersonRegisteredAsStudentHasIndexNumber on DayReservationDetails after insert, update as
	if (select Student from inserted) = 1 and (select p.IndexNumber from Person as p inner join inserted as i on p.PersonID = i.PersonID) is null
	begin
		raiserror('Person without IndexNumber can not be registered as student', 16, 1)
		rollback transaction
		return
	end
go

--overlaping early bird discount