use pachuta_a

create table Client(
	ClientID int identity(1,1) primary key,
	
	PastReservationCount int not null check(PastReservationCount >= 0) default 0,
	TotalMoneySpent money not null check(TotalMoneySpent >= 0) default 0
);



create table Company(
	CompanyID int identity(1,1) primary key,
	ClientID int unique not null foreign key references Client(ClientID),
	
	CompanyName varchar(255) not null
);



create table Person(
	PersonID int identity(1,1) primary key,
	ClientID int unique foreign key references Client(ClientID),
	CompanyID int foreign key references Company(CompanyID),

	FirstName varchar(255) not null,
	LastName varchar(255) not null,
	
	constraint chk_ClientID_or_CompanyID_not_null check(ClientID is not null or CompanyID is not null) 
);



create table Conference(
	ConferenceID int identity(1,1) primary key,
	
	StudentDiscount float not null check(StudentDiscount>=0)
);



create table Price(
	PriceID int identity(1,1) primary key
);



create table [Day](
	DayID int identity(1,1) primary key,
	ConferenceID int not null foreign key references Conference(ConferenceID),
	PriceID int not null foreign key references Price(PriceID),

	[Date] date not null,
	Capacity int not null check(Capacity>=0),
	SlotsLeft int not null check(SlotsLeft > =0),

	constraint chk_SlotsLeft_Capacity_Day check(SlotsLeft <= Capacity)
);



create table Workshop(
	WorkshopID int identity(1,1) primary key,
	DayID int not null foreign key references [Day](DayID),
	
	StartTime time not null,
	EndTime time not null,
	Capacity int not null check(Capacity>=0),
	SlotsLeft int not null check(SlotsLeft > =0),
	Price money not null check(Price >= 0),

	constraint chk_SlotsLeft_Capacity_Workshop check(SlotsLeft <= Capacity),
	constraint chk_StartTime_EndTime  check(EndTime > StartTime)
);



create table Reservation(
	ReservationID int identity(1,1) primary key,
	ClientID int not null foreign key references Client(ClientID),

	ReservationTime datetime not null,
	Price money not null check(Price >= 0),
	Paid money not null check(Paid >= 0),

	constraint chk_Paid_Price check(Paid <= Price)
);



create table DayReservationDetails(
	DayID int not null foreign key references [Day](DayID),
	ReservationID int not null foreign key references Reservation(ReservationID),
	PersonID int foreign key references Person(PersonID),

	constraint pk_DayID_ReservationID primary key (DayID, ReservationID)
);



create table WorkshopReservationDetails(
	WorkshopID int not null foreign key references Workshop(WorkshopID),
	ReservationID int not null foreign key references Reservation(ReservationID),
	PersonID int foreign key references Person(PersonID),

	constraint pk_WorkshopID_ReservationID primary key (WorkshopID, ReservationID)
);