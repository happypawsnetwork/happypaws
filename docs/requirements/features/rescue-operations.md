# Rescue & Field Operations

The core functionality of Happy Paws centers on identifying animals in need, assessing urgency, and coordinating transport and medical care.

## AI Image Triage Pipeline
- ✅ **Reporting**: Any user can report an animal found in distress. The mobile app captures GPS coordinates and a photo.
- ✅ **Analysis**: The Google Gemini Vision API evaluates the photo and description to classify urgency into Critical, Moderate, or Low tiers.
- ❌ **Geo-targeted alerts**: Once triaged, FCM push notifications dispatch immediately to nearby registered fosters, transporters, and veterinarians.

## Transporter Coordination
- ❌ **Task claiming**: Transporters claim open transport requests to move animals between rescue sites, fosters, or vets.
- ✅ **Live tracking**: Once a task is accepted, transporters update the status through assigned, picked up, in transit, and delivered. The administration panel map reflects their progress in real time.

## Veterinary Review
- ❌ **Manual override**: Veterinarians receive prioritized alerts for Critical or Moderate cases. They review the AI triage assessment and confirm or override it based on professional judgment.
- ❌ **Medical guidance**: Vets use the private messaging system to give immediate first-aid or handling advice to the person on the scene.

## KYC & Role Verification
- ✅ To accept transport tasks, act as a foster, or provide veterinary guidance, users must submit specific identity or professional documents to the private storage bucket.
- ❌ Administrators review these documents in the Next.js web dashboard before unlocking role-specific capabilities.