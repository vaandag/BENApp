# V140 — Red Screen + Premium Comments

- Removed custom PopScope/manual delayed route pop from CommentsScreen. Flutter now owns route lifecycle; back navigation uses the normal Navigator pop path.
- Unfocuses the IME before explicit AppBar back without delaying route deactivation.
- Redesigned comment cards with premium glass/gradient surfaces, soft depth, refined avatar, metadata, action pills and spacing.
- Kept existing comment edit/delete and backend behavior.
- This is a targeted source fix; device verification must be done on the user's Redmi 8.
