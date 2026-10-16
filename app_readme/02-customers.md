# Customers

## 1. Purpose

Customers represent the people who request services from the company.

The customer module should remain simple.

------------------------------------------------------------------------

# 2. Customer Model

``` text
Customer
├── id
├── name
├── phone
├── address
├── createdAt
└── updatedAt
```

------------------------------------------------------------------------

# 3. Fields

  Field       Type         Required Description
  ----------- ---------- ---------- --------------------
  id          UUID              Yes Customer ID
  name        string            Yes Customer name
  phone       string            Yes Phone number
  address     string            Yes Customer address
  createdAt   datetime          Yes Creation timestamp
  updatedAt   datetime          Yes Last update

------------------------------------------------------------------------

# 4. Relations

``` text
Customer
   │
   │ 1:N
   ▼
Booking
```

One customer can have many bookings.

A booking belongs to one customer.

------------------------------------------------------------------------

# 5. Customer List

The customers page should show:

-   Name
-   Phone
-   Address
-   Number of bookings
-   Upcoming bookings count

Example:

``` text
Ahmed Ali
01000000000
Cairo
12 Bookings
3 Upcoming
```

------------------------------------------------------------------------

# 6. Search

Recommended search:

``` text
Customer Name
Phone
```

------------------------------------------------------------------------

# 7. Create Customer

Required fields:

``` text
Name
Phone
Address
```

The same form can also be opened from the Create Booking flow.

------------------------------------------------------------------------

# 8. Edit Customer

Admin can update:

-   Name
-   Phone
-   Address

Updating customer data does not create a new customer.

------------------------------------------------------------------------

# 9. Customer Details

The customer details page should show:

## Basic Information

``` text
Name
Phone
Address
```

## Upcoming Bookings

Show upcoming services with:

``` text
Date
Time
Service
Technician
Status
```

## Booking History

Show previous bookings with:

``` text
Date
Service
Technician
Status
Total Price
```

------------------------------------------------------------------------

# 10. Booking Count

Booking counts are derived from the Booking entity.

Example:

``` text
Total Bookings
Upcoming
Completed
Cancelled
```

No separate Customer Statistics table is needed.

------------------------------------------------------------------------

# 11. Important Rule

Do not create:

``` text
CustomerService
CustomerHistory
CustomerStatistics
```

These are derived from the customer's bookings.
