use pachuta_a

create table [Address](
	AddressID int identity(1,1) primary key,

	Street varchar(50) not null,
	PostalCode varchar(7) not null check(PostalCode LIKE '[0-9][0-9]-[0-9][0-9][0-9]'),
	City varchar(50) not null,
	Country varchar(50) not null

	constraint chk_address_duplication unique(Street, PostalCode, City, Country)
)



create table Person(
	PersonID int identity(1,1) primary key,

	FirstName varchar(50) not null,
	LastName varchar(50) not null,
)



create table Client(
	ClientID int identity(1,1) primary key,
	AddressID int foreign key references Address(AddressID) not null,

	[Login] varchar(50) unique not null,
	[Password] varchar(50) not null,
	Mail varchar(50) unique not null check (Mail LIKE '%_@_%._%'),
	Phone varchar(9) unique not null check (Phone LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	BankAccount varchar(26) unique not null unique,
		
	PastReservationCount int not null check(PastReservationCount >= 0) default 0,
	TotalMoneySpent money not null check(TotalMoneySpent >= 0) default 0
)



create table PersonClient(
	ClientID int foreign key references Client(ClientID) not null,
	PersonID int foreign key references Person(PersonID) not null,
	
	IndexNumber varchar(6) unique default null check (IndexNumber LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]'),

	constraint pk_ClientID_PersonID primary key (ClientID, PersonID)
)



create table Company(
	CompanyID int identity(1,1) primary key,
	ClientID int unique not null foreign key references Client(ClientID),
	
	CompanyName varchar(50) unique not null
)



create table Conference(
	ConferenceID int identity(1,1) primary key,
	AddressID int foreign key references Address(AddressID) not null,

	Name varchar(50) unique not null,
	Venue varchar(50) not null,

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

	constraint chk_SlotsFilled_Capacity_Day check(SlotsFilled <= Capacity)
)



create table WorkshopType(
	WorkshopTypeID int identity(1,1) primary key,
	
	Capacity int not null check(Capacity >= 0),
	Price money not null check(Price >= 0),
	Location varchar(50) not null,
)



create table WorkshopInstance(
	WorkshopInstanceID int identity(1,1) primary key,
	DayID int not null foreign key references [Day](DayID),
	WorkshopTypeID int not null foreign key references WorkshopType(WorkshopTypeID),
	
	StartTime time not null,
	EndTime time not null,
	Location varchar(255) not null,
	SlotsFilled int not null check(SlotsFilled >= 0) default 0,

	constraint chk_WorkshopType_StartTime_EndTime  check(EndTime > StartTime)
)



create table Reservation(
	ReservationID int identity(1,1) primary key,
	ClientID int not null foreign key references Client(ClientID),

	ReservationTime datetime not null default GETDATE(),
	Price money not null check(Price >= 0),
	Paid money not null check(Paid >= 0) default 0,
	Cancelled bit not null default 0,

	constraint chk_Paid_Price check(Paid <= Price)
)



create table DayReservationDetails(
	DayID int not null foreign key references [Day](DayID),
	ReservationID int not null foreign key references Reservation(ReservationID),
	PersonID int foreign key references Person(PersonID),

	constraint pk_DayID_ReservationID primary key (DayID, ReservationID),
	constraint uq_DayID_PersonID unique (DayID, PersonID)
)



create table WorkshopReservationDetails(
	WorkshopInstanceID int not null foreign key references WorkshopInstance(WorkshopInstanceID),
	ReservationID int not null foreign key references Reservation(ReservationID),
	PersonID int foreign key references Person(PersonID),

	constraint pk_WorkshopID_ReservationID primary key (WorkshopInstanceID, ReservationID),
	constraint uq_WorkshopInstanceID_PersonID unique (WorkshopInstanceID, PersonID)
)