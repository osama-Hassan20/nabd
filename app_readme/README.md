# Service Dashboard Documentation

## Scope

This documentation describes the current Admin Dashboard scope.

The system contains four main data areas:

1.  Bookings
2.  Customers
3.  Technicians
4.  Settings

## Files

``` text
00-data-model.md
01-bookings.md
02-customers.md
03-technicians.md
04-settings.md
```

## Core Relations

``` text
Customer
   │ 1:N
   ▼
Booking
   ▲
   │ N:1
Technician
   │
   │ 1:N
   ▼
TechnicianLeave

CompanySettings
   │
   ├── Working Days
   ├── Working Hours
   ├── Special Holidays
   ├── Default Hourly Rate
   └── Notification Settings
```

## Important Scope Decisions

### No Service Entity

The requested service is stored as plain text inside Booking:

``` text
serviceName
```

### No Technician App

Technicians are managed entirely from the Admin Dashboard.

### No Customer App

Customers are managed from the dashboard and can be created during
booking creation.

### No Separate Payment Entity

Payment information can remain part of the Booking for the current
scope.

### No Separate Notification Entity

Notifications are derived from bookings and settings.

### No Separate Statistics Entity

Statistics are calculated from existing data.

### Company Holidays

There are two types:

1.  Weekly fixed days off, such as every Friday.
2.  Special holidays, such as Eid or a company vacation.

Both are configured from Settings.

### Technician Leave

Technician-specific leave is separate from company holidays.

A company holiday affects everyone, while a technician leave affects
only one technician.
