# Technicians

## 1. Purpose

Technicians are the employees who are assigned to bookings.

There is no Technician App in the current scope.

Everything is managed from the Admin Dashboard.

------------------------------------------------------------------------

# 2. Technician Model

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

------------------------------------------------------------------------

# 3. Fields

  Field       Type         Required Description
  ----------- ---------- ---------- --------------------
  id          UUID              Yes Technician ID
  name        string            Yes Technician name
  phone       string            Yes Phone number
  age         integer           Yes Technician age
  image       string             No Image URL/path
  createdAt   datetime          Yes Creation timestamp
  updatedAt   datetime          Yes Last update

------------------------------------------------------------------------

# 4. Technician Leave

Technician-specific leave is different from company holidays.

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

Example:

``` json
{
  "id": "leave_1",
  "technicianId": "tech_1",
  "startDate": "2026-10-15",
  "endDate": "2026-10-17",
  "reason": "Personal leave"
}
```

------------------------------------------------------------------------

# 5. Technician Status

Do not store the current status as a permanent field if it can be
calculated.

Possible statuses:

``` text
available
busy
on_leave
```

Priority:

``` text
On Leave
   ↓
Busy
   ↓
Available
```

### On Leave

If the current date is inside a TechnicianLeave period.

### Busy

If the technician currently has an active booking.

### Available

If:

-   Not on leave
-   No active booking

------------------------------------------------------------------------

# 6. Technician List

Each technician card/table row should show:

``` text
Image
Name
Phone
Age
Current Status
Today's Booking Count
```

Example:

``` text
Ahmed
01000000000
28 years

Available

Today's Tasks: 3
```

------------------------------------------------------------------------

# 7. Technician Details

Show:

## Profile

``` text
Image
Name
Phone
Age
Status
```

## Today's Schedule

Show today's bookings:

``` text
10:00 - 12:00
Home Cleaning
Ahmed Customer
```

## Upcoming Bookings

Show future assigned bookings.

## Completed Bookings

Show completed booking count/history.

## Leave

Show technician leave periods.

------------------------------------------------------------------------

# 8. Add Technician

Fields:

``` text
Name
Phone
Age
Image
```

------------------------------------------------------------------------

# 9. Edit Technician

Admin can update:

``` text
Name
Phone
Age
Image
```

------------------------------------------------------------------------

# 10. Delete Technician

Before deleting a technician, check whether there are active/upcoming
bookings assigned to them.

Recommended behavior:

``` text
If upcoming bookings exist:
    Do not hard delete
    Require reassignment first
```

For MVP, this can also be implemented as a confirmation rule.

------------------------------------------------------------------------

# 11. Relations

``` text
Technician
   │
   ├──────── 1:N ────────> Booking
   │
   └──────── 1:N ────────> TechnicianLeave
```

------------------------------------------------------------------------

# 12. Important Rule

Company holidays are NOT technician leaves.

Example:

``` text
Friday
↓
Company-wide day off
↓
No bookings for everyone
```

While:

``` text
Sunday
↓
Company is working
↓
Ahmed is on leave
↓
Other technicians can still receive bookings
```
