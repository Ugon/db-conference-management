if exists (select * from sys.indexes where name = 'IX_Reservation_ClientID') drop index IX_Reservation_ClientID on Reservation
go
if exists (select * from sys.indexes where name = 'IX_DayReservation_DayID') drop index IX_DayReservation_DayID on DayReservation
go
if exists (select * from sys.indexes where name = 'IX_DayReservation_ReservationID') drop index IX_DayReservation_ReservationID on DayReservation
go
if exists (select * from sys.indexes where name = 'IX_WorkshopReservation_WorkshopInstanceID') drop index IX_WorkshopReservation_WorkshopInstanceID on WorkshopReservation
go
if exists (select * from sys.indexes where name = 'IX_WorkshopReservation_DayReservationID') drop index IX_WorkshopReservation_DayReservationID on WorkshopReservation
go
if exists (select * from sys.indexes where name = 'IX_DayReservationDetails_DayReservationID') drop index IX_DayReservationDetails_DayReservationID on DayReservationDetails
go
if exists (select * from sys.indexes where name = 'IX_DayReservationDetails_PersonID') drop index IX_DayReservationDetails_PersonID on DayReservationDetails
go
if exists (select * from sys.indexes where name = 'IX_WorkshopReservationDetails_DayReservationDetailsID') drop index IX_WorkshopReservationDetails_DayReservationDetailsID on WorkshopReservationDetails
go
if exists (select * from sys.indexes where name = 'IX_WorkshopReservationDetails_WorkshopReservationID') drop index IX_WorkshopReservationDetails_WorkshopReservationID on WorkshopReservationDetails
go
if exists (select * from sys.indexes where name = 'IX_Day_ConferenceID') drop index IX_Day_ConferenceID on [Day]
go
if exists (select * from sys.indexes where name = 'IX_WorkshopInstance_DayID') drop index IX_WorkshopInstance_DayID on WorkshopInstance
go
if exists (select * from sys.indexes where name = 'IX_WorkshopInstance_WorkshopTypeID') drop index IX_WorkshopInstance_WorkshopTypeID on WorkshopInstance
go
if exists (select * from sys.indexes where name = 'IX_EarlyBirdDiscount_ConferenceID') drop index IX_EarlyBirdDiscount_ConferenceID on EarlyBirdDiscount
go

create index IX_Reservation_ClientID on Reservation(ClientID)
create index IX_DayReservation_DayID on DayReservation(DayID)
create index IX_DayReservation_ReservationID on DayReservation(ReservationID)
create index IX_WorkshopReservation_WorkshopInstanceID on WorkshopReservation(WorkshopInstanceID)
create index IX_WorkshopReservation_DayReservationID on WorkshopReservation(DayReservationID)
create index IX_DayReservationDetails_DayReservationID on DayReservationDetails(DayReservationID)
create index IX_DayReservationDetails_PersonID on DayReservationDetails(PersonID)
create index IX_WorkshopReservationDetails_DayReservationDetailsID on WorkshopReservationDetails(DayReservationDetailsID)
create index IX_WorkshopReservationDetails_WorkshopReservationID on WorkshopReservationDetails(WorkshopReservationID)
create index IX_Day_ConferenceID on [Day](ConferenceID)
create index IX_WorkshopInstance_DayID on WorkshopInstance(DayID)
create index IX_WorkshopInstance_WorkshopTypeID on WorkshopInstance(WorkshopTypeID)
create index IX_EarlyBirdDiscount_ConferenceID on EarlyBirdDiscount(ConferenceID)

select * from sys.indexes order by 2