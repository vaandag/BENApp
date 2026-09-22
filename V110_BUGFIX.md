# BENApp V110 – BUGFIX / UI CLEANUP

- Auth register/login moved from modal bottom sheet to a dedicated route to avoid `_dependents.isEmpty` lifecycle crashes.
- Bio editor remains a dedicated route and closes before parent profile state is updated.
- Profile main header no longer repeats the BEN brand; it shows `Senin Dünyan`.
- Home top bar replaces live + notification actions with a single `Mesajlar` action.
- Bottom navigation remains BEN / Harita / Keşfet / Mesajlar / Profil.
- Version: 5.1.5+110.
