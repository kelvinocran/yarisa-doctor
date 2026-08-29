# Doctor App UI Guidelines

Keep screens small, reusable, and consistent. Follow this when redesigning or adding doctor-app UI.

## File size

| Kind | Soft limit | Hard stop |
|------|------------|-----------|
| Screen (`lib/screens/**`) | **250 lines** | **400 lines** |
| Component / widget | **150 lines** | **250 lines** |
| Shared chrome / theme | **200 lines** | **300 lines** |

If a file is approaching the soft limit, **extract a component** instead of growing the screen.

## Folder layout

```
lib/
  ui/
    doctor_ui.dart          # scaffold, colors, section headers, empty states
  components/
    home/                   # home-only widgets
    appointments/           # appointment list/cards/stream helpers
    chat/                   # inbox + thread widgets
  screens/
    main/                   # thin screens that compose components
```

## Design system (`DoctorUi`)

- Use `DoctorScaffold` for page chrome (title + optional subtitle + body).
- Surfaces: white / dark `0xFF151515`, scaffold bg soft grey / near-black.
- Primary: `YarisaColors.primaryColor` (purple).
- Cards: 16–18 radius, light border, no heavy shadows.
- Sticky CTAs sit in a bottom bar with top border when needed.
- Prefer `Material` + `InkWell` under tappable rows (avoids ink warnings).

## UX patterns

1. **Empty / error / loading** — always handle all three; never blank screens.
2. **Pull to refresh** on lists fed by API or Firestore.
3. **Search** — debounced or simple `onChanged` + filter in memory is fine for small lists.
4. **Status pills** — shared status colors (pending amber, approved green, canceled red).
5. **Haptics** — light selection feedback on important taps when useful.

## Data / permissions

- Doctor appointment queries must use `doctorId` **and** legacy `doctor_id` (and optionally `providerId`).
- Never fail a whole screen if one of two field queries fails — merge what succeeds.
- Rules live in `yarisa-patient/firebase/firestore.rules` (shared project `mobile-doctors-5dea5`).
- After rule changes: deploy with  
  `firebase deploy --only firestore:rules --project mobile-doctors-5dea5`  
  from `yarisa-patient/firebase` (or repo root that has that firebase.json).

## What not to do

- Do not paste large private widgets into screens.
- Do not put Firestore transaction logic inside UI widgets — keep actions in helpers or API.
- Do not introduce a second design language; match patient-app card/chrome where possible.
- Do not leave `ListTile` without a `Material` ancestor when nested in decorated boxes.

## Checklist before finishing a redesign

- [ ] Screen under ~250 lines
- [ ] New UI bits live in `components/` or `ui/`
- [ ] Loading / empty / error states present
- [ ] `dart analyze` clean on touched files
- [ ] Permission-sensitive queries are resilient
