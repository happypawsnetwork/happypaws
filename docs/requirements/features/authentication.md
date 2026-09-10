# Authentication & Authorization

This document specifies the authentication constraints and role-based access for the Happy Paws platform.

## Mobile Application (Flutter)
- ✅ **Login mechanism**: Username and password login exclusively.
- ✅ **Session management**: 
  - No "Remember Me" functionality. 
  - Short-lived JWTs (15-30 minutes expiration). 
  - 30-day rolling refresh token securely stored in Flutter Secure Storage. 
  - 31-day absolute inactivity limit requires a hard re-login.
- ✅ **Admin restrictions**: Administrator accounts are hard-blocked from logging into the mobile application.

## Web Admin Application (Next.js)
- ✅ **Login mechanism**: Strict HTTP-Only, Secure, SameSite=Strict cookies. No "Remember Me" feature.
- ✅ **Two-factor authentication (2FA)**: Mandatory OTP via email, powered by the Resend API.
- ✅ **Session limits**: 8-12 hour absolute shift limit per login. 30-minute idle timeout requiring re-authentication.

## Registration & Onboarding (All Users)
- ✅ User provides an email address and the system sends an OTP.
- ✅ User enters the OTP to confirm email ownership.
- ✅ User provides necessary profile details.
- ✅ Account is created.

## Forgot Password Flow
- ✅ User requests a password reset via email.
- ✅ System emails an OTP, and the user enters it to verify identity.
- ✅ User sets a new password.

## Rate Limiting (Strict Enforcement)
- ✅ **Redis integration**: Redis strictly limits OTP generation, login attempts, and password resets.
- ✅ **Lockout policy**: Accounts and IP addresses lock out after 3-5 failed login or OTP attempts to mitigate brute-force attacks.

## Seed Admin Account
- ✅ The API creates an initial administrator account on boot if no admin exists in the system. The system emails these credentials via Resend and prints them to the console logs.

## Seed Development Accounts
- ✅ In development mode only, the API seeds five test accounts (`adopter@` as unverified, and `foster@`, `transporter@`, `vet@`, and `sponsor@happypawsnetwork.com` as verified) with default password 123.