select * from client
select * from company
select * from person 
select * from PersonClient
select * from Conference
select * from EarlyBirdDiscount
select * from WorkshopType
select * from [Address]
select * from [Day]
select * from WorkshopInstance

select * from Reservation
select * from DayReservation
select * from WorkshopReservation
select * from DayReservationDetails
select * from WorkshopReservationDetails



select t.CompanyName, count(*) as 'NumberOfEmployees' from 
(select distinct c.CompanyName, drd.PersonID from company as c
inner join client as cl on c.ClientID = cl.ClientID
inner join Reservation as r on r.ClientID = cl.ClientID
inner join DayReservation as dr on dr.ReservationID = r.ReservationID
inner join DayReservationDetails as drd on drd.DayReservationID = dr.DayReservationID) as t
group by t.CompanyName


--paying script
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