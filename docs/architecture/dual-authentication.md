# Authentication Architecture

In ASP.NET Core, an API often needs to authenticate users coming from different types of clients. In the Happy Paws platform, we support two distinct clients with different security models:
- **Web Admin App (Next.js)**: Sends session data via an HTTP-only Cookie (`SameSite=Strict`).
- **Mobile App (Flutter)**: Sends session data via a JWT in the `Authorization` header.

## How Dual Schemes Work

Registering both schemes teaches the API how to read and validate both token formats. The challenge is telling the API which method to check when a request arrives.

## The Forwarded Policy Approach

A forwarded policy acts as an automatic traffic director. You create a custom default scheme (like `"JWT_OR_COOKIE"`) that inspects the incoming HTTP request before processing it. 

If the request contains an `Authorization: Bearer` header, the policy forwards the validation task to the JWT handler. If that header is missing, it forwards the task to the Cookie handler. This allows the exact same API endpoint to securely accept requests from both the web app and the mobile app without writing duplicate code.

## The Route-Specific Approach

Alternatively, you can skip the automatic traffic director and explicitly tell each route what to expect. You configure authorization policies that name the required scheme. 

You then apply these policies directly to the endpoints. A mobile-specific route demands the JWT scheme, and a web-admin route demands the Cookie scheme. If the wrong client tries to access the route, the server immediately rejects the request.

---
*Note: In the Happy Paws implementation, we utilize the Forwarded Policy approach to seamlessly route incoming requests based on the presence of the Authorization header.*
## Session Lifespan and Security

The session is configured to be intentionally short-lived to minimize the risk of an unattended admin terminal being compromised:

- **30-Minute Idle Timeout**: If the administrator does not interact with the dashboard for 30 minutes, the session expires (this is a "sliding" window that resets on activity).
- **8-Hour Absolute Limit**: Regardless of how active the administrator is, the session has a hard cutoff of 8 hours. After an 8-hour shift, they are forced to completely re-authenticate and go through 2FA again.
