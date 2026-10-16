# Settings

## 1. Purpose

Settings contain the company-wide configuration used by the booking
system.

The settings module should remain small.

------------------------------------------------------------------------

# 2. Company Settings Model

``` text
CompanySettings
├── id
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

------------------------------------------------------------------------

# 3. Company Information

Fields:

``` text
Company Name
Logo
Phone
Address
```

------------------------------------------------------------------------

# 4. Working Days

The company defines which days are working days.

Example:

``` text
Saturday   ✓
Sunday     ✓
Monday     ✓
Tuesday    ✓
Wednesday  ✓
Thursday   ✓
Friday     ✕
```

This means Friday is a fixed weekly day off.

The important concept is:

``` text
Working Days
```

instead of creating individual recurring holiday records.

------------------------------------------------------------------------

# 5. Working Hours

Settings:

``` text
Opening Time
Closing Time
```

Example:

``` text
09:00 → 18:00
```

Bookings should not be created outside these hours.

------------------------------------------------------------------------

# 6. Default Hourly Rate

Example:

``` text
Default Hourly Rate = 100
```

When creating a booking:

``` text
Settings.defaultHourlyRate
          ↓
Booking.hourlyRate
```

The booking keeps its own rate.

Changing the default later does not change old bookings.

------------------------------------------------------------------------

# 7. Special Holidays

In addition to weekly days off, the company can add special holidays.

Examples:

-   Eid Al-Fitr
-   Eid Al-Adha
-   National holiday
-   Company vacation
-   Any exceptional day

Model:

``` text
SpecialHoliday
├── id
├── name
├── startDate
└── endDate
```

Example:

``` json
{
  "id": "holiday_1",
  "name": "Eid Al-Fitr",
  "startDate": "2027-03-09",
  "endDate": "2027-03-11"
}
```

------------------------------------------------------------------------

# 8. Weekly Days Off vs Special Holidays

These are two different concepts.

## Weekly Days Off

Repeated every week.

Example:

``` text
Every Friday
```

## Special Holidays

Specific dates.

Example:

``` text
9 March → 11 March
Eid Al-Fitr
```

Both should prevent creating bookings during the affected dates.

------------------------------------------------------------------------

# 9. Notification Settings

Keep notifications simple.

Example:

``` text
Service Reminder
Enabled: true
Reminder: 60 minutes before
```

The exact notification implementation can be handled separately.

No Notification entity is required for the current MVP.

------------------------------------------------------------------------

# 10. Settings Screen

Suggested sections:

``` text
Company Information
    ├── Company Name
    ├── Logo
    ├── Phone
    └── Address

Working Schedule
    ├── Working Days
    ├── Opening Time
    └── Closing Time

Pricing
    └── Default Hourly Rate

Special Holidays
    ├── List Holidays
    ├── Add Holiday
    ├── Edit Holiday
    └── Delete Holiday

Notifications
    └── Service Reminder
```

------------------------------------------------------------------------

# 11. Booking Validation Using Settings

Before creating a booking:

``` text
Is selected day a working day?
        │
        ├── No → Reject
        │
        └── Yes
             ↓
Is selected date a special holiday?
        │
        ├── Yes → Reject
        │
        └── No
             ↓
Is time within working hours?
        │
        ├── No → Reject
        │
        └── Yes
             ↓
Create Booking
```

------------------------------------------------------------------------

# 12. Important Scope

Do NOT add these settings in the current MVP:

``` text
Tax Configuration
Accounting
Cancellation Policies
Booking Limits
Buffer Time
Maximum Booking Duration
Payment Gateway Configuration
Customer Rules
Complex Pricing Rules
```

Only keep the settings required for the current booking workflow.
