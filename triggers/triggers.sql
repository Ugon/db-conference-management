use pachuta_a


-------------------------------------------------------------------------------------------
---------------AUXILIARY FUNCTIONS---------------------------------------------------------
-------------------------------------------------------------------------------------------

if object_id('calculateDaySlotsFilled') is not null drop function calculateDaySlotsFilled
go
create function calculateDaySlotsFilled(@DayID int) returns int as begin
	return isnull((select sum(dr.NumberOfParticipants) from [Day] as d
		inner join DayReservation as dr on d.DayID = dr.DayID
		inner join Reservation as r on r.ReservationID = dr.ReservationID
		where d.DayID = @DayID and r.Cancelled = 0), 0)
end
go

if object_id('calculateWorkshopSlotsFilled') is not null drop function calculateWorkshopSlotsFilled
go
create function calculateWorkshopSlotsFilled(@WorkshopInstanceID int) returns int as begin
	return isnull((select sum(dr.NumberOfParticipants) from WorkshopInstance as wi
		 inner join WorkshopReservation as wr on wi.WorkshopInstanceID = wr.WorkshopInstanceID
		 inner join DayReservation as dr on dr.DayReservationID = wr.DayReservationID
		 inner join Reservation as r on r.ReservationID = dr.ReservationID
		 where wi.WorkshopInstanceID = @WorkshopInstanceID and r.Cancelled = 0), 0)
end
go

if object_id('calculateDayPrice') is not null drop function calculateDayPrice
go
create function calculateDayPrice(@DayID int , @ReservationTime datetime, @Student bit) returns money as begin
	declare @StudentDiscount float = 0
	declare @EarlyBirdDiscount float = 0
	declare @DayPrice money
	declare @PriceAfterDiscount money
	if @Student = 1
		set @StudentDiscount = (select c.StudentDiscount from Conference as c inner join [Day] as d on d.ConferenceID = c.ConferenceID where d.DayID = @DayID)
	set @EarlyBirdDiscount = isnull((select ebd.Discount from [Day] as d
		inner join Conference as c on c.ConferenceID = d.ConferenceID
		inner join EarlyBirdDiscount as ebd on c.ConferenceID = ebd.ConferenceID
		where d.DayID = @DayID and ebd.StartTime <= @ReservationTime and @ReservationTime < ebd.EndTime), 0)
	set @DayPrice = (select c.DayPrice from Conference as c 
		inner join [Day] as d on c.ConferenceID = d.ConferenceID
		where d.DayID = @DayID)
	set @PriceAfterDiscount = @DayPrice * (1 - @EarlyBirdDiscount) * (1 - @StudentDiscount)
	return @PriceAfterDiscount
end
go

if object_id('calculateDayReservationPriceWithSplitArguments') is not null drop function calculateDayReservationPriceWithSplitArguments
go
create function calculateDayReservationPriceWithSplitArguments(@DayID int, @ReservationTime datetime, @NumberOfParticipants int, @NumberOfStudentDiscounts int) returns money as begin
	declare @StudentPrice money
	declare @NormalPrice money
	exec @StudentPrice = calculateDayPrice @DayID, @ReservationTime, @Student = 1
	exec @NormalPrice = calculateDayPrice @DayID, @ReservationTime, @Student = 0	
	return @StudentPrice * @NumberOfStudentDiscounts + @NormalPrice * (@NumberOfParticipants - @NumberOfStudentDiscounts)
end
go

if object_id('calculateDayReservationPrice') is not null drop function calculateDayReservationPrice
go
create function calculateDayReservationPrice(@DayReservationID int) returns money as begin
	declare @DayID int = (select DayID from DayReservation where DayReservationID = @DayReservationID)
	declare @ReservationTime datetime = (select r.ReservationTime from Reservation as r inner join DayReservation as dr on r.ReservationID = dr.ReservationID where dr.DayReservationID = @DayReservationID)
	declare @NumberOfParticipants int = (select NumberOfParticipants from DayReservation where DayReservationID = @DayReservationID)
	declare @NumberOfStudentDiscounts int = (select NumberOfStudentDiscounts from DayReservation where DayReservationID = @DayReservationID)
	declare @Result money
	exec @Result = calculateDayReservationPriceWithSplitArguments @DayID, @ReservationTime, @NumberOfParticipants, @NumberOfStudentDiscounts
	return @Result
end
go

if object_id('calculateWorkshopPrice') is not null drop function calculateWorkshopPrice
go
create function calculateWorkshopPrice(@WorkshopInstanceID int, @Student bit) returns money as begin
	declare @StudentDiscount float = 0
	declare @Price money
	if @Student = 1
		set @StudentDiscount = (select c.StudentDiscount from WorkshopInstance as wi
		inner join [Day] as d on wi.DayID = d.DayID
		inner join Conference as c on c.ConferenceID = d.ConferenceID
		where wi.WorkshopInstanceID = @WorkshopInstanceID)
	set @Price = (select wt.Price from WorkshopInstance as wi
		inner join WorkshopType as wt on wt.WorkshopTypeID = wi.WorkshopTypeID
		where wi.WorkshopInstanceID = @WorkshopInstanceID)
	return @Price * (1 - @StudentDiscount)
end
go

if object_id('calculateWorkshopReservationPriceWithSplitArguments') is not null drop function calculateWorkshopReservationPriceWithSplitArguments
go
create function calculateWorkshopReservationPriceWithSplitArguments(@WorkshopInstanceID int, @NumberOfParticipants int, @NumberOfStudentDiscounts int) returns money as begin
	declare @StudentPrice money
	declare @NormalPrice money
	exec @StudentPrice = calculateWorkshopPrice @WorkshopInstanceID, @Student = 1
	exec @NormalPrice = calculateWorkshopPrice @WorkshopInstanceID, @Student = 0	
	return @StudentPrice * @NumberOfStudentDiscounts + @NormalPrice * (@NumberOfParticipants - @NumberOfStudentDiscounts)
end
go

if object_id('calculateWorkshopReservationPrice') is not null drop function calculateWorkshopReservationPrice
go
create function calculateWorkshopReservationPrice(@WorkshopReservationID int) returns money as begin
	declare @WorkshopInstanceID int = (select WorkshopInstanceID from WorkshopReservation where WorkshopReservationID = @WorkshopReservationID)
	declare @NumberOfParticipants int = (select NumberOfParticipants from WorkshopReservation where WorkshopReservationID = @WorkshopReservationID)
	declare @NumberOfStudentDiscounts int = (select NumberOfStudentDiscounts from WorkshopReservation where WorkshopReservationID = @WorkshopReservationID)
	declare @Result money
	exec @Result = calculateWorkshopReservationPriceWithSplitArguments @WorkshopInstanceID, @NumberOfParticipants, @NumberOfStudentDiscounts
	return @Result
end
go

if object_id('calculateReservationPrice') is not null drop function calculateReservationPrice
go
create function calculateReservationPrice(@ReservationID int) returns money as begin
	declare @DayReservationID int
	declare @WorkshopReservationID int
	declare @Result money = 0
	declare @temp money

	declare DayReservationIDs cursor for select DayReservationID from DayReservation where ReservationID = @ReservationID
	open DayReservationIDs
	fetch next from DayReservationIDs into @DayReservationID
	while @@fetch_status = 0 begin
		exec @temp = calculateDayReservationPrice @DayReservationID
		set @Result += @Temp
		
		declare WorkshopReservationIDs cursor for select WorkshopReservationID from WorkshopReservation where DayReservationID = @DayReservationID
		open WorkshopReservationIDs
		fetch next from WorkshopReservationIDs into @WorkshopReservationID
		while @@fetch_status = 0 begin
			exec @temp = calculateWorkshopReservationPrice @WorkshopReservationID
			set @Result += @Temp
			fetch next from WorkshopReservationIDs into @WorkshopReservationID
		end
		close WorkshopReservationIDs
		deallocate WorkshopReservationIDs

		fetch next from DayReservationIDs into @DayReservationID
	end
	close DayReservationIDs
	deallocate DayReservationIDs

	return @Result
end
go


-------------------------------------------------------------------------------------------
---------------CALCULATE TRIGGERS----------------------------------------------------------
-------------------------------------------------------------------------------------------

if object_id('calculateDaySlotsFilledAfterReservationCancel') is not null drop trigger calculateDaySlotsFilledAfterReservationCancel
go
--SlotsFilled <= Capacity enforced by constraint
create trigger calculateDaySlotsFilledAfterReservationCancel on Reservation after update as
if exists (select * from deleted where Cancelled = 0) and exists (select * from inserted where Cancelled = 1) begin
	declare @DayID int
	declare @DaySlotsFilled int
	declare AffectedDays cursor for select dr.DayID from DayReservation as dr inner join inserted as i on i.ReservationID = dr.ReservationID
	open AffectedDays
	fetch next from AffectedDays into @DayID
	while @@fetch_status = 0 begin
		exec @DaySlotsFilled = calculateDaySlotsFilled @DayID = @DayID
		update [Day] set SlotsFilled = @DaySlotsFilled where DayID = @DayID
		fetch next from AffectedDays into @DayID
	end
	close AffectedDays
	deallocate AffectedDays
end
go

if object_id('calculateWorkshopSlotsFilledAfterReservationCancel') is not null drop trigger calculateWorkshopSlotsFilledAfterReservationCancel
go
--SlotsFilled <= Capacity enforced by constraint
create trigger calculateWorkshopSlotsFilledAfterReservationCancel on Reservation after update as
if exists (select * from deleted where Cancelled = 0) and exists (select * from inserted where Cancelled = 1) begin
	declare @WorkshopInstanceID int
	declare @WorkshopSlotsFilled int
	declare AffectedWorkshops cursor for select wr.WorkshopInstanceID from WorkshopReservation as wr inner join DayReservation as dr on wr.DayReservationID = dr.DayReservationID inner join inserted as i on i.ReservationID = dr.ReservationID
	open AffectedWorkshops
	fetch next from AffectedWorkshops into @WorkshopInstanceID
	while @@fetch_status = 0 begin
		exec @WorkshopSlotsFilled = calculateWorkshopSlotsFilled @WorkshopInstanceID = @WorkshopInstanceID
		update WorkshopInstance set SlotsFilled = @WorkshopSlotsFilled where WorkshopInstanceID = @WorkshopInstanceID
		fetch next from AffectedWorkshops into @WorkshopInstanceID
	end
	close AffectedWorkshops
	deallocate AffectedWorkshops
end
go

if object_id('calculateDaySlotsFilledAfterInsertingDayReservation') is not null drop trigger calculateDaySlotsFilledAfterInsertingDayReservation
go
--SlotsFilled <= Capacity enforced by constraint
create trigger calculateDaySlotsFilledAfterInsertingDayReservation on DayReservation after insert as begin
	declare @DayID int = (select DayID from inserted)
	declare @NumberOfParticipants int = (select NumberOfParticipants from inserted)
	update [Day] set SlotsFilled += @NumberOfParticipants where DayID = @DayID
end
go

if object_id('calculateWorkshopSlotsFilledAfterInsertingWorkshopReservation') is not null drop trigger calculateWorkshopSlotsFilledAfterInsertingWorkshopReservation
go
--SlotsFilled <= Capacity enforced by constraint
create trigger calculateWorkshopSlotsFilledAfterInsertingWorkshopReservation on WorkshopReservation after insert as begin
	declare @WorkshopInstanceID int = (select WorkshopInstanceID from inserted)
	declare @NumberOfParticipants int = (select NumberOfParticipants from inserted)
	update WorkshopInstance set SlotsFilled += @NumberOfParticipants where WorkshopInstanceID = @WorkshopInstanceID
end
go

if object_id('calculateDaySlotsFilledAfterUpdatingDayReservation') is not null drop trigger calculateDaySlotsFilledAfterUpdatingDayReservation
go
--SlotsFilled <= Capacity enforced by constraint
create trigger calculateDaySlotsFilledAfterUpdatingDayReservation on DayReservation after update as begin
	declare @DayID int = (select DayID from inserted)
	declare @BilansOfParticipants int = (select NumberOfParticipants from inserted) - (select NumberOfParticipants from deleted)
	update [Day] set SlotsFilled += @BilansOfParticipants where DayID = @DayID
end
go

if object_id('calculateWorkshopSlotsFilledAfterUpdatingWorkshopReservation') is not null drop trigger calculateWorkshopSlotsFilledAfterUpdatingWorkshopReservation
go
--SlotsFilled <= Capacity enforced by constraint
create trigger calculateWorkshopSlotsFilledAfterUpdatingWorkshopReservation on WorkshopReservation after update as begin
	declare @WorkshopInstanceID int = (select WorkshopInstanceID from inserted)
	declare @BilansOfParticipants int = (select NumberOfParticipants from inserted) - (select NumberOfParticipants from deleted)
	update WorkshopInstance set SlotsFilled += @BilansOfParticipants where WorkshopInstanceID = @WorkshopInstanceID
end
go

if object_id('calculateDaySlotsFilledAfterDeletingDayReservation') is not null drop trigger calculateDaySlotsFilledAfterDeletingDayReservation
go
--SlotsFilled <= Capacity enforced by constraint
create trigger calculateDaySlotsFilledAfterDeletingDayReservation on DayReservation after delete as begin
	declare @DayID int = (select DayID from deleted)
	declare @NumberOfParticipants int = (select NumberOfParticipants from deleted)
	update [Day] set SlotsFilled -= @NumberOfParticipants where DayID = @DayID
end
go

if object_id('calculateWorkshopSlotsFilledAfterDeletingWorkshopReservation') is not null drop trigger calculateWorkshopSlotsFilledAfterDeletingWorkshopReservation
go
--SlotsFilled <= Capacity enforced by constraint
create trigger calculateWorkshopSlotsFilledAfterDeletingWorkshopReservation on WorkshopReservation after delete as begin
	declare @WorkshopInstanceID int = (select WorkshopInstanceID from deleted)
	declare @NumberOfParticipants int = (select NumberOfParticipants from deleted)
	update WorkshopInstance set SlotsFilled -= @NumberOfParticipants where WorkshopInstanceID = @WorkshopInstanceID
end
go

if object_id('calculateReservationPriceAfterDayReservationInsertUpdate') is not null drop trigger calculateReservationPriceAfterDayReservationInsertUpdate
go
create trigger calculateReservationPriceAfterDayReservationInsertUpdate on DayReservation after insert, update as begin
	declare @ReservationID int = (select ReservationID from inserted)
	declare @Price money
	exec @Price = calculateReservationPrice @ReservationID
	update Reservation set Price = @Price where ReservationID = @ReservationID
end
go

if object_id('calculateReservationPriceAfterDayReservationDelete') is not null drop trigger calculateReservationPriceAfterDayReservationDelete
go
create trigger calculateReservationPriceAfterDayReservationDelete on DayReservation after delete as begin
	declare @ReservationID int = (select ReservationID from deleted)
	declare @Price money
	exec @Price = calculateReservationPrice @ReservationID
	update Reservation set Price = @Price where ReservationID = @ReservationID
end
go

if object_id('calculateReservationPriceAfterWorkshopReservationInsertUpdate') is not null drop trigger calculateReservationPriceAfterWorkshopReservationInsertUpdate
go
create trigger calculateReservationPriceAfterWorkshopReservationInsertUpdate on WorkshopReservation after insert, update as begin
	declare @ReservationID int = (select dr.ReservationID from inserted as i inner join DayReservation as dr on dr.DayReservationID = i.DayReservationID)
	declare @Price money
	exec @Price = calculateReservationPrice @ReservationID
	update Reservation set Price = @Price where ReservationID = @ReservationID
end
go

if object_id('calculateReservationPriceAfterWorkshopReservationDelete') is not null drop trigger calculateReservationPriceAfterWorkshopReservationDelete
go
create trigger calculateReservationPriceAfterWorkshopReservationDelete on WorkshopReservation after delete as begin
	declare @ReservationID int = (select dr.ReservationID from deleted as d inner join DayReservation as dr on dr.DayReservationID = d.DayReservationID)
	declare @Price money
	exec @Price = calculateReservationPrice @ReservationID
	update Reservation set Price = @Price where ReservationID = @ReservationID
end
go

if object_id('calculatePastReservationCountAfterReservationModification') is not null drop trigger calculatePastReservationCountAfterReservationModification
go
create trigger calculatePastReservationCountAfterReservationModification on Reservation after insert, update as begin
	declare @ClientID int = (select ClientID from inserted)
	declare @PastReservationCount int = (select count(*) from Reservation as r where r.ClientID = @ClientID and r.Cancelled = 0)
	update Client set PastReservationCount = @PastReservationCount where ClientID = @ClientID
end
go

if object_id('calculateTotalMoneySpentAfterReservationModification') is not null drop trigger calculateTotalMoneySpentAfterReservationModification
go
create trigger calculateTotalMoneySpentAfterReservationModification on Reservation after insert, update as begin
	declare @ClientID int = (select ClientID from inserted)
	declare @TotalMoneySpent int = isnull((select sum(r.Paid) from Reservation as r where r.ClientID = @ClientID and r.Cancelled = 0), 0)
	update Client set TotalMoneySpent = @TotalMoneySpent where ClientID = @ClientID
end
go



-------------------------------------------------------------------------------------------
---------------CHECK TRIGGERS--------------------------------------------------------------
-------------------------------------------------------------------------------------------

if object_id('checkThatPersonWorkshopReservationsDoNotOverlap') is not null drop trigger checkThatPersonWorkshopReservationsDoNotOverlap
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

if object_id('checkThatWorkshopNumberOfParticipantsIsNotGreaterThanDayNumberOfParticipants') is not null drop trigger checkThatWorkshopNumberOfParticipantsIsNotGreaterThanDayNumberOfParticipants
go
create trigger checkThatWorkshopNumberOfParticipantsIsNotGreaterThatDayNumberOfParticipants on WorkshopReservation after insert as
	if (select NumberOfParticipants from inserted) > (select dr.NumberOfParticipants from inserted as i inner join DayReservation as dr on i.DayReservationID = dr.DayReservationID)
	begin
		raiserror('WorkshopReservation NumberOfParticipants is greater than DayReservation NumberOfParticipants', 16, 1)
		rollback transaction
		return
	end
go

if object_id('checkThatWorkshopNumberOfStudentDiscountsisNotGreaterThanDayNumberOfStudentDiscounts') is not null drop trigger checkThatWorkshopNumberOfStudentDiscountsisNotGreaterThanDayNumberOfStudentDiscounts
go
create trigger checkThatWorkshopNumberOfStudentDiscountsisNotGreaterThanDayNumberOfStudentDiscounts on WorkshopReservation after insert as
	if (select NumberOfStudentDiscounts from inserted) > (select dr.NumberOfStudentDiscounts from inserted as i inner join DayReservation as dr on i.DayReservationID = dr.DayReservationID)
	begin
		raiserror('WorkshopReservation NumberOfStudentDiscount is greater than DayReservation NumberOfStudentDiscount', 16, 1)
		rollback transaction
		return
	end
go

if object_id('checkThatDayNumberOfStudentDiscountsIsNotLesserThanActualNumberOfStudentDayReservationDetails') is not null drop trigger checkThatDayNumberOfStudentDiscountsIsNotLesserThanActualNumberOfStudentDayReservationDetails
go
create trigger checkThatDayNumberOfStudentDiscountsIsNotLesserThanActualNumberOfStudentDayReservationDetails on DayReservationDetails after insert, update as
	if(select count(*) from DayReservationDetails as drd inner join inserted as i on i.DayReservationID = drd.DayReservationID where drd.Student = 1)
		> (select NumberOfStudentDiscounts from DayReservation as dr inner join inserted as i on dr.DayReservationID = i.DayReservationID)
		begin
	raiserror('Number of registered students for day exceeds DayReservation NumberOfStudentDiscounts limit', 16, 1)
		rollback transaction
		return
	end
go

if object_id('checkThatWorkshopNumberOfStudentDiscountsIsNotLesserThanActualNumberOfStudentWorkshopReservationDetails') is not null drop trigger checkThatWorkshopNumberOfStudentDiscountsIsNotLesserThanActualNumberOfStudentWorkshopReservationDetails
go
create trigger checkThatWorkshopNumberOfStudentDiscountsIsNotLesserThanActualNumberOfStudentWorkshopReservationDetails on WorkshopReservationDetails after insert, update as
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

if object_id('checkThatPersonRegisteredAsStudentHasIndexNumber') is not null drop trigger checkThatPersonRegisteredAsStudentHasIndexNumber
go
create trigger checkThatPersonRegisteredAsStudentHasIndexNumber on DayReservationDetails after insert, update as
	if (select Student from inserted) = 1 and (select p.IndexNumber from Person as p inner join inserted as i on p.PersonID = i.PersonID) is null
	begin
		raiserror('Person without IndexNumber can not be registered as student', 16, 1)
		rollback transaction
		return
	end
go

if object_id('checkThatClientIDIsNotAlreadyTakenByCompanyWhenAddingPersonClient') is not null drop trigger checkThatClientIDIsNotAlreadyTakenByCompanyWhenAddingPersonClient
go
create trigger checkThatClientIDIsNotAlreadyTakenByCompanyWhenAddingPersonClient on PersonClient after insert as
	if exists (select * from Company as c inner join inserted as i on i.ClientID = c.ClientID)
	begin
		raiserror('ClientID already exists in Company', 16, 1)
		rollback transaction
		return
	end
go

if object_id('checkThatClientIDIsNotAlreadyTakenByPersonWhenAddingCompany') is not null drop trigger checkThatClientIDIsNotAlreadyTakenByPersonWhenAddingCompany
go
create trigger checkThatClientIDIsNotAlreadyTakenByPersonWhenAddingCompany on Company after insert as
	if exists (select * from PersonClient as pc inner join inserted as i on i.ClientID = pc.ClientID)
	begin
		raiserror('ClientID already exists in PersonClient', 16, 1)
		rollback transaction
		return
	end
go

if object_id('checkThatEarlyBirdsDiscountsDoNotOverlap') is not null drop trigger checkThatEarlyBirdsDiscountsDoNotOverlap
go
create trigger checkThatEarlyBirdsDiscountsDoNotOverlap on EarlyBirdDiscount after insert, update as
	declare @EarlyBirdDiscounts table(EarlyBirdDiscountID int primary key, StartTime time, EndTime time)
	insert into @EarlyBirdDiscounts (EarlyBirdDiscountID, StartTime, EndTime)
		select ebd.EarlyBirdDiscountID, ebd.StartTime, ebd.EndTime from EarlyBirdDiscount as ebd
		inner join inserted as i on i.ConferenceID = ebd.ConferenceID
	if exists (select * from @EarlyBirdDiscounts as t1 inner join @EarlyBirdDiscounts as t2 on t1.EarlyBirdDiscountID != t2.EarlyBirdDiscountID
		where (t1.StartTime < t2.EndTime and t2.EndTime < t1.EndTime) or (t1.StartTime < t2.StartTime and t2.StartTime < t1.EndTime))
	begin
		raiserror('Overlaping EarlyBirdDiscounts', 16, 1)
		rollback transaction
		return
	end
go

if object_id('checkThatThereIsNoInsertOrUpdateOnDayReservationAfterPayment') is not null drop trigger checkThatThereIsNoInsertOrUpdateOnDayReservationAfterPayment
go
create trigger checkThatThereIsNoInsertOrUpdateOnDayReservationAfterPayment on DayReservation after insert, update as begin
	if (select r.Paid from Reservation as r inner join inserted as i on r.ReservationID = i.ReservationID) != 0 begin
		raiserror('Attempting to modify a reservation that was already paid for', 16, 1)
		rollback transaction
		return
	end
end
go

if object_id('checkThatThereIsNoDeleteOnDayReservationAfterPayment') is not null drop trigger checkThatThereIsNoDeleteOnDayReservationAfterPayment
go
create trigger checkThatThereIsNoDeleteOnDayReservationAfterPayment on DayReservation after delete as begin
	if (select r.Paid from Reservation as r inner join deleted as d on r.ReservationID = d.ReservationID) != 0 begin
		raiserror('Attempting to modify a reservation that was already paid for', 16, 1)
		rollback transaction
		return
	end
end
go

if object_id('checkThatThereIsNoInsertUpdateOnWorkshopReservationAfterPayment') is not null drop trigger checkThatThereIsNoInsertUpdateOnWorkshopReservationAfterPayment
go
create trigger checkThatThereIsNoInsertUpdateOnWorkshopReservationAfterPayment on WorkshopReservation after insert, update as begin
	if (select r.Paid from Reservation as r
			inner join DayReservation as dr on r.ReservationID = dr.ReservationID
			inner join inserted as i on dr.DayReservationID = i.DayReservationID) != 0 begin
		raiserror('Attempting to modify a reservation that was already paid for', 16, 1)
		rollback transaction
		return
	end
end
go

if object_id('checkThatThereIsNoDeleteOnWorkshopReservationAfterPayment') is not null drop trigger checkThatThereIsNoDeleteOnWorkshopReservationAfterPayment
go
create trigger checkThatThereIsNoDeleteOnWorkshopReservationAfterPayment on WorkshopReservation after delete as begin
	if (select r.Paid from Reservation as r
			inner join DayReservation as dr on r.ReservationID = dr.ReservationID
			inner join deleted as d on dr.DayReservationID = d.DayReservationID) != 0 begin
		raiserror('Attempting to modify a reservation that was already paid for', 16, 1)
		rollback transaction
		return
	end
end
go

if object_id('checkDayReservationNumberOfParticipantsAfterUpdatingDayReservation') is not null drop trigger checkDayReservationNumberOfParticipantsAfterUpdatingDayReservation
go
create trigger checkDayReservationNumberOfParticipantsAfterUpdatingDayReservation on DayReservation after update as begin
	if(select NumberOfParticipants from inserted) < (select NumberOfParticipants from deleted) begin
		if (select count(*) from DayReservationDetails as drd inner join inserted as i on i.DayReservationID = drd.DayReservationID) > (select NumberOfParticipants from inserted)
			raiserror('Insterted NumberOfParticipants can not accomodate all currently enlisted participants', 16, 1)
			rollback transaction
			return
	end
end
go

if object_id('checkDayReservationNumberOfStudentsAfterUpdatingWorkshopReservation') is not null drop trigger checkDayReservationNumberOfStudentsAfterUpdatingWorkshopReservation
go
create trigger checkDayReservationNumberOfStudentsAfterUpdatingWorkshopReservation on WorkshopReservation after update as begin
	if(select NumberOfStudentDiscounts from inserted) < (select NumberOfStudentDiscounts from deleted) begin
		if (select count(*) from DayReservationDetails as drd inner join inserted as i on i.DayReservationID = drd.DayReservationID where drd.Student = 1) > (select NumberOfStudentDiscounts from inserted)
			raiserror('Insterted NumberOfStudentDiscounts can not accomodate all currently enlisted students', 16, 1)
			rollback transaction
			return
	end
end
go

if object_id('checkWorkshopReservationNumberOfParticipantsAfterUpdatingWorkshopReservation') is not null drop trigger checkWorkshopReservationNumberOfParticipantsAfterUpdatingWorkshopReservation
go
create trigger checkWorkshopReservationNumberOfParticipantsAfterUpdatingWorkshopReservation on WorkshopReservation after update as begin
	if(select NumberOfParticipants from inserted) < (select NumberOfParticipants from deleted) begin
		if (select count(*) from WorkshopReservationDetails as wrd inner join inserted as i on i.DayReservationID = wrd.WorkshopReservationID) > (select NumberOfParticipants from inserted)
			raiserror('Insterted NumberOfParticipants can not accomodate all currently enlisted participants', 16, 1)
			rollback transaction
			return
	end
end
go

if object_id('checkWorkshopReservationNumberOfStudentsAfterUpdatingWorkshopReservation') is not null drop trigger checkWorkshopReservationNumberOfStudentsAfterUpdatingWorkshopReservation
go
create trigger checkWorkshopReservationNumberOfStudentsAfterUpdatingWorkshopReservation on WorkshopReservation after update as begin
	if(select NumberOfStudentDiscounts from inserted) < (select NumberOfStudentDiscounts from deleted) begin
		if (select count(*) from WorkshopReservationDetails as wrd
			inner join inserted as i on i.WorkshopReservationID = wrd.WorkshopReservationID 
			inner join DayReservationDetails as drd on drd.DayReservationDetailsID = wrd.DayReservationDetailsID
			where drd.Student = 1) > (select NumberOfStudentDiscounts from inserted)
			raiserror('Insterted NumberOfStudentDiscounts can not accomodate all currently enlisted students', 16, 1)
			rollback transaction
			return
	end
end
go