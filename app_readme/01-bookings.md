# Bookings

## 1. Purpose

Bookings are the core feature of the dashboard.

The admin can:

-   View bookings in a calendar.
-   See booking count for each day.
-   Open a specific day and see its bookings.
-   Filter bookings.
-   Create a new booking.
-   Edit a booking.
-   Assign/change technician.
-   Cancel a booking.
-   Mark a booking as completed.

------------------------------------------------------------------------

# 2. Booking Model

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

------------------------------------------------------------------------

# 3. Fields

  -------------------------------------------------------------------------
  Field             Type                          Required Description
  ----------------- ---------------- --------------------- ----------------
  id                UUID                               Yes Booking ID

  customerId        UUID                               Yes Related customer

  technicianId      UUID                                No Assigned
                                                           technician

  serviceName       string                             Yes Requested
                                                           service as plain
                                                           text

  bookingType       enum                               Yes `one_time` /
                                                           `recurring`

  date              date                       Conditional Used for
                                                           one-time
                                                           bookings

  recurrence        object                     Conditional Used for
                                                           recurring
                                                           bookings

  startTime         time                               Yes Start time

  endTime           time                               Yes End time

  durationMinutes   integer                            Yes Calculated
                                                           duration

  hourlyRate        decimal                            Yes Rate used for
                                                           this booking

  totalPrice        decimal                            Yes Calculated total

  status            enum                               Yes Booking status

  paymentStatus     enum                                No Payment state if
                                                           payment tracking
                                                           is enabled

  notes             string                              No Additional notes

  createdAt         datetime                           Yes Creation
                                                           timestamp

  updatedAt         datetime                           Yes Last update
  -------------------------------------------------------------------------

------------------------------------------------------------------------

# 4. Booking Status

MVP statuses:

``` text
scheduled
completed
cancelled
```

Optional later:

``` text
in_progress
```

------------------------------------------------------------------------

# 5. Payment Status

If payment tracking is enabled, keep it simple:

``` text
unpaid
paid
```

No separate Payment entity is required for the MVP.

------------------------------------------------------------------------

# 6. One-Time Booking

Required:

``` text
Customer
Service Name
Date
Start Time
End Time
Hourly Rate
Technician (optional)
```

Example:

``` json
{
  "bookingType": "one_time",
  "date": "2026-10-10",
  "startTime": "10:00",
  "endTime": "13:00"
}
```

------------------------------------------------------------------------

# 7. Recurring Booking

A recurring booking contains:

``` text
recurrence
├── frequency
├── daysOfWeek
├── startDate
└── endDate
```

Example:

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

This means the booking repeats every Sunday and Tuesday during the
selected period.

------------------------------------------------------------------------

# 8. Calendar

The Bookings page is centered around a calendar.

Each day should show the number of bookings:

``` text
Sun  Mon  Tue  Wed  Thu  Fri  Sat
 3    1    4    0    2    -    1
```

A day off can be visually distinguished.

Clicking a day opens the bookings for that day.

------------------------------------------------------------------------

# 9. Filters

Required filter:

-   Customer name

Recommended filters:

-   Technician
-   Booking status

The date itself is controlled by the calendar.

------------------------------------------------------------------------

# 10. Create Booking Flow

``` text
Create Booking
      │
      ▼
Select Customer
      │
      ├── Existing Customer
      │
      └── Add New Customer
              │
              ├── Name
              ├── Phone
              └── Address
      │
      ▼
Service Name
      │
      ▼
Booking Type
      │
      ├── One Time
      │      └── Select Date
      │
      └── Recurring
             ├── Frequency
             ├── Days
             ├── Start Date
             └── End Date
      │
      ▼
Start Time
      │
      ▼
End Time
      │
      ▼
Hourly Rate
      │
      ▼
Technician
      │
      ▼
Create
```

------------------------------------------------------------------------

# 11. New Customer During Booking

The admin should not be forced to leave the booking screen.

They can select:

``` text
+ Add New Customer
```

Fields:

``` text
Name
Phone
Address
```

After saving the customer, that customer becomes selected for the
booking.

------------------------------------------------------------------------

# 12. Price Calculation

``` text
durationHours = endTime - startTime

totalPrice = durationHours × hourlyRate
```

Example:

``` text
10:00 → 13:00
Duration = 3 hours

Hourly Rate = 100

Total = 300
```

------------------------------------------------------------------------

# 13. Default Hourly Rate

When creating a booking:

``` text
Settings.defaultHourlyRate
             ↓
        Booking.hourlyRate
```

The value is copied to the booking.

If the company later changes its default rate, existing bookings keep
their old rate.

------------------------------------------------------------------------

# 14. Technician Assignment

`technicianId` can be null.

This allows:

``` text
Booking
   ↓
Unassigned
```

The dashboard can show a warning for unassigned bookings.

Before assigning a technician, check:

-   Technician leave.
-   Existing overlapping booking.

------------------------------------------------------------------------

# 15. Availability Rules

A booking cannot be created if:

``` text
Selected date is a weekly day off
OR
Selected date is a special holiday
OR
Time is outside company working hours
OR
Technician is on leave
OR
Technician has another booking at the same time
```

------------------------------------------------------------------------

# 16. Booking Details

Booking details should display:

-   Customer
-   Phone
-   Address
-   Service name
-   Date
-   Start time
-   End time
-   Duration
-   Technician
-   Hourly rate
-   Total price
-   Status
-   Notes

Actions:

``` text
Edit
Change Technician
Cancel
Mark as Completed
```

------------------------------------------------------------------------

# 17. Relations

``` text
Customer
   │
   │ 1:N
   ▼
Booking
   ▲
   │ N:1
   │
Technician
```

------------------------------------------------------------------------

# 18. Important Rule

There is no Service table.

This:

``` text
serviceName: "AC Repair"
```

is enough for the current scope.
