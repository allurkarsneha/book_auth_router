# HW4 Book Auth Router

This Flutter app implements the HW4 authentication and routing flow using `AuthenticationBloc`, `GoRouter`, `ShellRoute`, and redirect logic.

## Features

- Login and logout flow
- Authentication-based redirect
- `AuthenticationBloc` placed above `MaterialApp.router`
- `RefreshListenable` created from the authentication stream
- `ShellRoute` for the main pages
- Bottom navigation for By Author, By Title, and Profile
- Books sorted by author
- Books sorted by title
- Book detail page

## Routes

```text
/login
/byAuthor
/byAuthor/detail
/byTitle
/byTitle/detail
/profile
