--use pachuta_a
--go
if object_id('WorkshopReservationDetails') is not null drop table WorkshopReservationDetails
go
if object_id('DayReservationDetails') is not null drop table DayReservationDetails
go
if object_id('WorkshopReservation') is not null drop table WorkshopReservation
go
if object_id('DayReservation') is not null drop table DayReservation
go
if object_id('Reservation') is not null drop table Reservation
go
if object_id('PersonClient') is not null drop table PersonClient
go
if object_id('Person') is not null drop table Person
go
if object_id('Company') is not null drop table Company
go
if object_id('Client') is not null drop table Client
go
if object_id('WorkshopInstance') is not null drop table WorkshopInstance
go
if object_id('WorkshopType') is not null drop table WorkshopType
go
if object_id('[Day]') is not null drop table [Day]
go
if object_id('EarlyBirdDiscount') is not null drop table EarlyBirdDiscount
go
if object_id('Conference') is not null drop table Conference
go
if object_id('[Address]') is not null drop table [Address]
go

create table [Address](
	AddressID int identity(1,1) primary key,

	Street varchar(200) not null,
	PostalCode varchar(6) not null check(PostalCode LIKE '[0-9][0-9]-[0-9][0-9][0-9]'),
	City varchar(200) not null,
	Country varchar(200) not null

	constraint chk_address_duplication unique(Street, PostalCode, City, Country)
)



create table Person(
	PersonID int identity(1,1) primary key,

	FirstName varchar(200) not null,
	LastName varchar(200) not null,
	IndexNumber varchar(6) default null check (IndexNumber LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]'), --TODO: UNIQUE NULL WTF
	Mail varchar(200) unique not null check (Mail LIKE '%_@_%._%')
)



create table Client(
	ClientID int identity(1,1) primary key,
	AddressID int foreign key references Address(AddressID) not null,

	[Login] varchar(200) unique not null,
	[Password] varchar(200) not null,
	Phone varchar(11) unique not null check (Phone LIKE '[0-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9]'),
	BankAccount varchar(32) unique not null check (BankAccount LIKE '[0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9]'),
	PastReservationCount int not null check(PastReservationCount >= 0) default 0,
	TotalMoneySpent money not null check(TotalMoneySpent >= 0) default 0
)



create table PersonClient(
	ClientID int foreign key references Client(ClientID) not null unique,
	PersonID int foreign key references Person(PersonID) not null unique,

	constraint pk_ClientID_PersonID primary key (ClientID, PersonID)
)



create table Company(
	CompanyID int identity(1,1) primary key,
	ClientID int unique not null foreign key references Client(ClientID),
	
	CompanyName varchar(200) unique not null,
	Mail varchar(200) unique not null check (Mail LIKE '%_@_%._%')
)



create table Conference(
	ConferenceID int identity(1,1) primary key,
	AddressID int foreign key references Address(AddressID) not null,

	Name varchar(200) unique not null,
	Venue varchar(200) not null,

	DayPrice money not null check(DayPrice >= 0),
	StudentDiscount float not null check(StudentDiscount >= 0 and StudentDiscount <= 1) default 0
)



create table EarlyBirdDiscount(
	EarlyBirdDiscountID int identity(1,1) primary key,
	ConferenceID int not null foreign key references Conference(ConferenceID),

	StartTime datetime not null,
	EndTime datetime not null,
	Discount float not null check(Discount > 0 and Discount <= 1),

	constraint chk_EarlyBirdDiscount_StartTime_EndTime check(StartTime < EndTime)
)

create table [Day](
	DayID int identity(1,1) primary key,
	ConferenceID int not null foreign key references Conference(ConferenceID),

	[Date] date not null,
	Capacity int not null check(Capacity >= 0),
	SlotsFilled int not null check(SlotsFilled >= 0) default 0,

	constraint chk_SlotsFilled_Capacity_Day check(SlotsFilled <= Capacity),
	constraint uq_ConferenceID_Date unique(ConferenceID, [Date])
)



create table WorkshopType(
	WorkshopTypeID int identity(1,1) primary key,
	
	Name varchar(200) unique not null,
	Capacity int not null check(Capacity >= 0),
	Price money not null check(Price >= 0)
)



create table WorkshopInstance(
	WorkshopInstanceID int identity(1,1) primary key,
	DayID int not null foreign key references [Day](DayID),
	WorkshopTypeID int not null foreign key references WorkshopType(WorkshopTypeID),
	
	StartTime time not null,
	EndTime time not null,
	Location varchar(200) not null,
	SlotsFilled int not null check(SlotsFilled >= 0) default 0,

	constraint chk_WorkshopType_StartTime_EndTime check(EndTime > StartTime),
	constraint uq_WorkshopTypeID_DayID_StartTime unique(DayID, WorkshopTypeID, StartTime)
)



create table Reservation(
	ReservationID int identity(1,1) primary key,
	ClientID int not null foreign key references Client(ClientID),

	ReservationTime datetime not null default GETDATE(),
	Price money not null check(Price >= 0) default 0,
	Paid money not null check(Paid >= 0) default 0,
	Cancelled bit not null default 0,

	constraint chk_Paid_Price check(Paid <= Price)
)



create table DayReservation(
	DayReservationID int identity(1,1) primary key,
	DayID int not null foreign key references [Day](DayID),
	ReservationID int not null foreign key references Reservation(ReservationID),

	NumberOfParticipants int not null check(NumberOfParticipants > 0),
	NumberOfStudentDiscounts int not null default 0 check(NumberOfStudentDiscounts >= 0),

	constraint uq_DayID_ReservationID unique (DayID, ReservationID),
	constraint chk_DayReservation_Participants_Students check (NumberOfParticipants >= NumberOfStudentDiscounts)
)



create table WorkshopReservation(
	WorkshopReservationID int identity(1,1) primary key,
	WorkshopInstanceID int not null foreign key references WorkshopInstance(WorkshopInstanceID),
	DayReservationID int not null foreign key references DayReservation(DayReservationID),

	NumberOfParticipants int not null check(NumberOfParticipants > 0),
	NumberOfStudentDiscounts int not null default 0 check(NumberOfStudentDiscounts >= 0),

	constraint uq_WorkshopInstanceID_DayReservationID unique (WorkshopInstanceID, DayReservationID),
	constraint chk_WorkshopReservation_Participants_Students check (NumberOfParticipants >= NumberOfStudentDiscounts)
)



create table DayReservationDetails(
	DayReservationDetailsID int identity(1,1) primary key,
	DayReservationID int not null foreign key references DayReservation(DayReservationID),
	PersonID int not null foreign key references Person(PersonID),

	Student bit not null default 0,

	constraint uq_DayReservationDetails unique (DayReservationID, PersonID)
)



create table WorkshopReservationDetails(
	DayReservationDetailsID int not null foreign key references DayReservationDetails(DayReservationDetailsID),
	WorkshopReservationID int not null foreign key references WorkshopReservation(WorkshopReservationID),

	constraint pk_WorkshopReservationDetails primary key(DayReservationDetailsID, WorkshopReservationID),
)
