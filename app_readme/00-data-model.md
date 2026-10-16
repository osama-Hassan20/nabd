# Service Dashboard --- Data Model

## 1. Scope

النظام عبارة عن Admin Dashboard بسيط لإدارة شركة خدمات.

الـ Core Data Entities هي:

-   Booking
-   Customer
-   Technician
-   Company Settings

> لا يوجد `Service` entity.\
> الخدمة داخل الحجز عبارة عن نص فقط مثل: `Home Cleaning`, `AC Repair`,
> `Plumbing`.

------------------------------------------------------------------------

## 2. Relationships

``` text
Customer
   │
   │ 1 : N
   ▼
Booking
   ▲
   │ N : 1
   │
Technician

Technician
   │
   │ 1 : N
   ▼
TechnicianLeave

CompanySettings
   │
   ├── Weekly Days Off
   ├── Special Holidays
   ├── Working Hours
   ├── Default Hourly Rate
   └── Notification Settings
```

### Relations

  Entity             Relation   Entity
  ------------------ ---------- -------------------------
  Customer           1:N        Booking
  Technician         1:N        Booking
  Technician         1:N        TechnicianLeave
  Company Settings   1:1        Dashboard configuration

------------------------------------------------------------------------

# 3. Customer

``` text
Customer
├── id
├── name
├── phone
├── address
├── createdAt
└── updatedAt
```

### Fields

  Field       Type            Required Description
  ----------- ------------- ---------- --------------------
  id          string/UUID          Yes Unique customer ID
  name        string               Yes Customer name
  phone       string               Yes Customer phone
  address     string               Yes Customer address
  createdAt   datetime             Yes Creation date
  updatedAt   datetime             Yes Last update

------------------------------------------------------------------------

# 4. Technician

``` text
Technician
├── id
├── name
├── phone
├── age
├── image
├── createdAt
└── updatedAt
```

Technician leave is represented separately:

``` text
Technician
   │
   │ 1:N
   ▼
TechnicianLeave
├── id
├── technicianId
├── startDate
├── endDate
└── reason
```

Technician status should preferably be calculated rather than stored
permanently.

``` text
On Leave
    ↓
Busy
    ↓
Available
```

Priority:

1.  On Leave
2.  Busy
3.  Available

------------------------------------------------------------------------

# 5. Booking

``` text
Booking
├── id
├── customerId
├── technicianId
├── serviceName
├── bookingType
├── date
├── recurrence
├── startTime
├── endTime
├── durationMinutes
├── hourlyRate
├── totalPrice
├── status
├── paymentStatus
├── notes
├── createdAt
└── updatedAt
```

### Important

`serviceName` is just a text field.

There is NO:

``` text
Service
ServiceCategory
ServicePrice
ServiceDuration
```

entity in the current system.

------------------------------------------------------------------------

# 6. Booking Types

## One Time

``` json
{
  "bookingType": "one_time",
  "date": "2026-10-10",
  "startTime": "10:00",
  "endTime": "13:00"
}
```

## Recurring

``` json
{
  "bookingType": "recurring",
  "recurrence": {
    "frequency": "weekly",
    "daysOfWeek": [
      "sunday",
      "tuesday"
    ],
    "startDate": "2026-10-11",
    "endDate": "2026-11-11"
  }
}
```

The recurring booking represents a repeated schedule.

For the MVP, the calendar can calculate the occurrences from the
recurrence configuration instead of introducing another large entity.

------------------------------------------------------------------------

# 7. Company Settings

``` text
CompanySettings
├── companyName
├── logo
├── phone
├── address
├── defaultHourlyRate
├── workingDays
├── openingTime
├── closingTime
├── specialHolidays[]
└── notificationSettings
```

## Weekly Working Days

Weekly days off are configured here.

Example:

``` json
{
  "workingDays": [
    "saturday",
    "sunday",
    "monday",
    "tuesday",
    "wednesday",
    "thursday"
  ]
}
```

Friday is therefore a weekly day off.

------------------------------------------------------------------------

# 8. Special Holidays

Special holidays are also part of Settings.

``` text
SpecialHoliday
├── id
├── name
├── startDate
└── endDate
```

Examples:

-   Eid Al-Fitr
-   Eid Al-Adha
-   Company holiday
-   Any exceptional closure

Example:

``` json
{
  "id": "holiday_1",
  "name": "Eid Al-Fitr",
  "startDate": "2027-03-09",
  "endDate": "2027-03-11"
}
```

There is no need for a standalone Holiday module in the application.

------------------------------------------------------------------------

# 9. Booking Price

The default hourly rate comes from Settings:

``` text
CompanySettings.defaultHourlyRate
```

When a booking is created, the current rate is copied into:

``` text
Booking.hourlyRate
```

This is important because changing the default rate later must not
change old bookings.

Formula:

``` text
durationHours × hourlyRate = totalPrice
```

Example:

``` text
3 hours × 100 = 300
```

------------------------------------------------------------------------

# 10. Booking Availability Rules

A booking should only be created when:

1.  The selected date is a working day.
2.  The date is not a special company holiday.
3.  The time is inside company working hours.
4.  End time is after start time.
5.  The assigned technician is not on leave.
6.  The assigned technician does not have another overlapping booking.

------------------------------------------------------------------------

# 11. Important Design Decision

Do not create separate entities for:

-   Services
-   Payments
-   Notifications
-   Statistics
-   Dashboard

unless the system grows enough to actually require them.

These are currently represented by booking/settings data and derived
views.
