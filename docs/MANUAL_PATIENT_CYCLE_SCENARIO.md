# Manual Patient Cycle QA Scenario (Per Specialty)

This scenario covers the end-to-end flow for any enabled `MedicalSpecialty` in the clinic.

## Preconditions
- Clinic is in Local Mode (or Online Mode with `FakeRemoteSyncApi`).
- Seeded doctors exist for every specialty (`DOC-01` through `DOC-13`).

## Steps per Specialty `S`
1. **Reception — Patient Intake**:
   - Open Patients -> Add Patient.
   - For **Pediatrics**: enter DOB < 18 years and complete Guardian fields.
   - For **OB/GYN**: select Female, Marital Status (`مدام`), check `حامل`, enter LMP (verify EDD = LMP + 280 days and gestational weeks/month display).
   - Verify Female section is hidden when Gender = Male, and Pregnancy fields are hidden for Female age < 12.
2. **Reception — Booking & Payment**:
   - Create a booking with a doctor of specialty `S`.
   - Open Cashier shift (if not open) and collect payment for the booking.
   - Verify booking shows `specialtyCode = S`.
3. **Nurse — Vitals & Triage**:
   - Open Visits Queue -> record vitals (BP, pulse, temp, weight, height).
4. **Doctor of `S` — Consultation & Specialty Module**:
   - Start consultation from the booking.
   - Verify the specialty record section for `S` appears under Consultation (and multi-specialty doctors can access their specialty modules).
   - Enter specialty-specific data:
     - **Pediatrics**: weight, height, head circumference, BMI/WHO percentile (reference), mark a vaccine dose given.
     - **OB/GYN**: antenatal BP/FHR/fundal height, verify pregnancy countdown (`الشهر X من 9 / باقي Y أسبوع`).
     - **Dentistry**: select FDI tooth (32 adult / 20 child), record treatment & session `X of N`, book next session.
     - **Dermatology / Cosmetic / Orthodontics / Physiotherapy**: add session/package (`X of N`), book next session.
   - Add diagnosis, prescription (verify warning if prescribing a drug flagged `unsafeInPregnancy` / `unsafeInLactation`), and lab/radiology order. Finalize visit.
5. **Verification & Restart**:
   - Open Patient Details -> verify visit appears in history and specialty entry appears in the Specialty Record tab.
   - Refresh / Restart app -> verify patient, booking, visit, specialty entry, and cashier payment persist.
6. **Reconnect & Sync Gate**:
   - Switch from Local Mode back to Online Mode.
   - Verify the blocking Sync Review Dialog opens automatically.
   - Verify changes are grouped by Arabic section (`المرضى`, `الحجوزات والمواعيد`, `الزيارات الطبية`, `السجل التخصصي`, `الخزينة والورديات`).
   - Test "البقاء في الوضع المحلي" escape, then reopen and sync one item, discard one item (verify rollback), and "مزامنة الكل".
