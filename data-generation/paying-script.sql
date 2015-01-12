use pachuta_a
go

declare @ReservationID int
declare NotCancelled cursor for select ReservationID from Reservation where Cancelled = 0
open NotCancelled
fetch next from NotCancelled into @ReservationID
while @@fetch_status = 0 begin
	declare @Price money = (select Price from Reservation where ReservationID = @ReservationID)
	exec addPayment @ReservationID, @Price
	fetch next from NotCancelled into @ReservationID
end
close NotCancelled
deallocate NotCancelled