class CashierPolicy {
  final int maxUnapprovedShortagePiastres; // Default: 5000 (50 EGP)
  final int maxPettyExpensePiastres;       // Default: 20000 (200 EGP)
  final int maxShiftAgeHours;             // Default: 16 hours

  const CashierPolicy({
    this.maxUnapprovedShortagePiastres = 5000,
    this.maxPettyExpensePiastres = 20000,
    this.maxShiftAgeHours = 16,
  });
}

