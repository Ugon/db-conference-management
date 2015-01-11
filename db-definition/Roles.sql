use pachuta_a

IF DATABASE_PRINCIPAL_ID('organizer') IS NOT NULL
drop role organizer
GO

CREATE ROLE organizer;

GRANT EXECUTE ON [dbo].[addConference] TO organizer;
GRANT EXECUTE ON [dbo].[addConferenceDay] TO organizer;
GRANT EXECUTE ON [dbo].[addEarlyBirdDiscount] TO organizer;
GRANT EXECUTE ON [dbo].[addWorkshopInstance] TO organizer;
GRANT EXECUTE ON [dbo].[addWorkshopType] TO organizer;
GRANT EXECUTE ON [dbo].[addClientCompany] TO organizer;
GRANT EXECUTE ON [dbo].[addClientPerson] TO organizer;

GRANT SELECT ON [dbo].[AllConferences] TO organizer;
GRANT SELECT ON [dbo].[FutureConferences] TO organizer;
GRANT SELECT ON [dbo].[DaysOfFutureConferences] TO organizer;
GRANT SELECT ON [dbo].[DaysOfAllConferences] TO organizer;
GRANT SELECT ON [dbo].[EarlyBirdDiscountInformation] TO organizer;
GRANT SELECT ON [dbo].[WorkshopsOfFutureConferences] TO organizer;
GRANT SELECT ON [dbo].[WorkshopsOfAllConferences] TO organizer;
GRANT SELECT ON [dbo].[AllReservations] TO organizer;
GRANT SELECT ON [dbo].[PendingReservations] TO organizer;
GRANT SELECT ON [dbo].[UnpaidReservations] TO organizer;
GRANT SELECT ON [dbo].[PersonClients] TO organizer;
GRANT SELECT ON [dbo].[CompanyClients] TO organizer;
GRANT SELECT ON [dbo].[MoneySpentStatisticsForCompanyClients] TO organizer;
GRANT SELECT ON [dbo].[MoneySpentStatisticsForPersonClients] TO organizer;
GRANT SELECT ON [dbo].[unfilledDayReservations] TO organizer;
GRANT SELECT ON [dbo].[unfilledWorkshopReservations] TO organizer;

GRANT SELECT ON [dbo].[ConferenceParticipants] TO organizer;
GRANT SELECT ON [dbo].[DayParticipants] TO organizer;
GRANT SELECT ON [dbo].[WorkshopParticipants] TO organizer;
GRANT SELECT ON [dbo].[AllClientReservations] TO organizer;
GRANT SELECT ON [dbo].[mostPopularWorkshopTypes] TO organizer;
GRANT SELECT ON [dbo].[BadgesForConferenceParticipants] TO organizer;


IF DATABASE_PRINCIPAL_ID('personClient') IS NOT NULL
drop role personClient
GO

CREATE ROLE personClient;

GRANT EXECUTE ON [dbo].[addNewReservation] TO personClient;
GRANT EXECUTE ON [dbo].[addPayment] TO personClient;
GRANT EXECUTE ON [dbo].[addDayReservationForPerson] TO personClient;
GRANT EXECUTE ON [dbo].[addWorkshopReservationForPerson] TO personClient;
GRANT EXECUTE ON [dbo].[cancelReservation] TO personClient;
GRANT EXECUTE ON [dbo].[cancelDayReservation] TO personClient;
GRANT EXECUTE ON [dbo].[cancelWorkshopReservation] TO personClient;
GRANT EXECUTE ON [dbo].[changeParticipantsStudentStatus] TO personClient;

GRANT SELECT ON [dbo].[FutureConferences] TO personClient;
GRANT SELECT ON [dbo].[DaysOfFutureConferences] TO personClient;
GRANT SELECT ON [dbo].[WorkshopsOfFutureConferences] TO personClient;
GRANT SELECT ON [dbo].[AllClientReservations] TO personClient;
GRANT SELECT ON [dbo].[ReservationDaysForPersonClient] TO personClient;
GRANT SELECT ON [dbo].[ReservationWorkshopsForPersonClient] TO personClient;

IF DATABASE_PRINCIPAL_ID('companyClient') IS NOT NULL
drop role companyClient
GO

CREATE ROLE companyClient;

GRANT EXECUTE ON [dbo].[addNewReservation] TO companyClient;
GRANT EXECUTE ON [dbo].[addPayment] TO companyClient;
GRANT EXECUTE ON [dbo].[addWorkshopReservationDetailsForCompany] TO companyClient;
GRANT EXECUTE ON [dbo].[addDayReservationDetailsForCompany] TO companyClient;
GRANT EXECUTE ON [dbo].[addDayReservationForCompany] TO companyClient;
GRANT EXECUTE ON [dbo].[addWorkshopReservationForCompany] TO companyClient;
GRANT EXECUTE ON [dbo].[removeDayReservationDetailsForCompany] TO companyClient;
GRANT EXECUTE ON [dbo].[removeWorkshopReservationDetailsForCompany] TO companyClient;
GRANT EXECUTE ON [dbo].[changeDayReservationNumbers] TO companyClient;
GRANT EXECUTE ON [dbo].[changeNumberOfParticipantsDay] TO companyClient;
GRANT EXECUTE ON [dbo].[changeNumberOfParticipantsWorkshop] TO companyClient;
GRANT EXECUTE ON [dbo].[changeNumberOfStudentsDay] TO companyClient;
GRANT EXECUTE ON [dbo].[changeNumberOfStudentsWorkshop] TO companyClient;
GRANT EXECUTE ON [dbo].[changeWorkshopReservationNumbers] TO companyClient;
GRANT EXECUTE ON [dbo].[changeParticipantsStudentStatus] TO companyClient;
GRANT EXECUTE ON [dbo].[removeParticipantDay] TO companyClient;
GRANT EXECUTE ON [dbo].[removeParticipantWorkshop] TO companyClient;
GRANT EXECUTE ON [dbo].[cancelDayReservation] TO companyClient
GRANT EXECUTE ON [dbo].[cancelReservation] TO companyClient
GRANT EXECUTE ON [dbo].[cancelWorkshopReservation] TO companyClient

GRANT SELECT ON [dbo].[FutureConferences] TO companyClient;
GRANT SELECT ON [dbo].[DaysOfFutureConferences] TO companyClient;
GRANT SELECT ON [dbo].[WorkshopsOfFutureConferences] TO companyClient;
GRANT SELECT ON [dbo].[AllClientReservations] TO companyClient;
GRANT SELECT ON [dbo].[ReservationDaysForCompanyClient] TO companyClient;
GRANT SELECT ON [dbo].[ReservationWorkshopsForCompanyClient] TO companyClient;
GRANT SELECT ON [dbo].[ReservationDayDetailsForCompanyClient] TO companyClient;
GRANT SELECT ON [dbo].[ReservationWorkshopDetailsForCompanyClient] TO companyClient;
GRANT SELECT ON [dbo].[ReservationFreeDaySlots] TO companyClient;
GRANT SELECT ON [dbo].[ReservationFreeWorkshopSlots] TO companyClient;

IF DATABASE_PRINCIPAL_ID('participant') IS NOT NULL
drop role participant
GO

CREATE ROLE participant;
GRANT SELECT ON [dbo].[ConferenceListForParticipant] TO participant;
GRANT SELECT ON [dbo].[DayListForParticipant] TO participant;
GRANT SELECT ON [dbo].[WorkshopListForParticipant] TO participant;
