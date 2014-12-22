use pachuta_a

create table [Address](
	AddressID int identity(1,1) primary key,
	Street varchar(255) not null,
	PostalCode varchar(255) not null,
	City varchar(255) not null,
	Country varchar(255) not null
)



create table Person(
	PersonID int identity(1,1) primary key,

	FirstName varchar(255) not null,
	LastName varchar(255) not null,
)



create table Client(
	ClientID int identity(1,1) primary key,
	AddressID int foreign key references Address(AddressID) unique not null,

	[Login] varchar(255) unique not null,
	[Password] varchar(255) not null,
	Mail varchar(255) not null,
	Phone varchar(255) not null,
	BankAccount varchar(255) not null unique,
		
	PastReservationCount int not null check(PastReservationCount >= 0) default 0,
	TotalMoneySpent money not null check(TotalMoneySpent >= 0) default 0
)



create table PersonClient(
	ClientID int foreign key references Client(ClientID) not null,
	PersonID int foreign key references Person(PersonID) not null,
	
	IndexNumber varchar(255) unique,

	constraint pk_ClientID_PersonID primary key (ClientID, PersonID)
)



create table Company(
	CompanyID int identity(1,1) primary key,
	ClientID int unique not null foreign key references Client(ClientID),
	
	CompanyName varchar(255) unique not null
)



create table Conference(
	ConferenceID int identity(1,1) primary key,
	AddressID int foreign key references Address(AddressID) unique not null,

	Name varchar(255) not null,
	Venue varchar(255) not null,
	DayPrice money not null check(DayPrice > 0),
	StudentDiscount float not null check(StudentDiscount > =0)
)



create table EarlyBirdDiscount(
	EarlyBirdDiscountID int identity(1,1) primary key,
	ConferenceID int not null foreign key references Conference(ConferenceID),

	StartTime datetime not null,
	EndTime datetime not null,
	Discount float not null check(Discount > 0),

	constraint chk_EarlyBirdDiscount_StartTime_EndTime check(StartTime < EndTime)
)



create table [Day](
	DayID int identity(1,1) primary key,
	ConferenceID int not null foreign key references Conference(ConferenceID),

	[Date] date not null,
	Capacity int not null check(Capacity >= 0),
	SlotsLeft int not null check(SlotsLeft >= 0),

	constraint chk_SlotsLeft_Capacity_Day check(SlotsLeft <= Capacity)
)



create table WorkshopType(
	WorkshopTypeID int identity(1,1) primary key,
	
	Name varchar(255) not null,
	StartTime time not null,
	EndTime time not null,
	Capacity int not null check(Capacity >= 0),
	Price money not null check(Price >= 0),
	Location varchar(255) not null,

	constraint chk_WorkshopType_StartTime_EndTime  check(EndTime > StartTime)
)



create table WorkshopInstance(
	WorkshopInstanceID int identity(1,1) primary key,
	DayID int not null foreign key references [Day](DayID),
	WorkshopTypeID int not null foreign key references WorkshopType(WorkshopTypeID),
	
	SlotsLeft int not null check(SlotsLeft >= 0),

	constraint uq_DayID_WorkshopTypeID unique(DayID, WorkshopTypeID)
)



create table Reservation(
	ReservationID int identity(1,1) primary key,
	ClientID int not null foreign key references Client(ClientID),

	ReservationTime datetime not null,
	Price money not null check(Price >= 0),
	Paid money not null check(Paid >= 0),
	Cancelled bit not null

	constraint chk_Paid_Price check(Paid <= Price)
)



create table DayReservationDetails(
	DayID int not null foreign key references [Day](DayID),
	ReservationID int not null foreign key references Reservation(ReservationID),
	PersonID int foreign key references Person(PersonID),

	constraint pk_DayID_ReservationID primary key (DayID, ReservationID)
)



create table WorkshopReservationDetails(
	WorkshopInstanceID int not null foreign key references WorkshopInstance(WorkshopInstanceID),
	ReservationID int not null foreign key references Reservation(ReservationID),
	PersonID int foreign key references Person(PersonID),

	constraint pk_WorkshopID_ReservationID primary key (WorkshopInstanceID, ReservationID)
)