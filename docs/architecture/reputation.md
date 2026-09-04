# User reputation and badges

This document outlines the Happy Paws reputation system. Users earn reputation points for their actions and unlock trust badges by reaching specific milestones.

## Reputation points

Users earn reputation points for participating in the Happy Paws community. These points reflect the user's overall contribution and trustworthiness.

### Action point values

| Action | Points | Description |
| --- | --- | --- |
| Adopt an animal | +100 | Awarded when an adoption application is accepted. |
| Foster an animal | +50 | Awarded when a foster placement is completed. |
| Fund a sponsorship | +50 | Awarded when a financial pledge is fulfilled. |
| Complete a transport | +20 | Awarded when a transport task is delivered. |
| Post a rescue alert | +10 | Awarded when a user creates a new rescue post. |
| Post a find home | +10 | Awarded when a user creates an adoption listing. |
| Post an update | +5 | Awarded for providing a progress report on an active rescue. |
| Post a highlight | +2 | Awarded for sharing a community story. |
| Receive a like | +1 | Awarded when a user's community post receives a like. |

## Badges

In addition to points, users earn badges for specific achievements. The system automatically awards these badges when technical conditions are met.

### Adoption and fostering

#### Welcome home
* **ID:** `WELCOME_HOME`
* **Description:** Awarded when a user adopts their first animal.
* **Technical condition:** The `adoption_applications` table updates to status `ACCEPTED` for an adopter who has no previous accepted applications.
* **Assignment mechanism:** An event handler listens for the adoption application status change, checks the adopter's history, and inserts a record into `user_badges` if the criteria are met.

#### Growing family
* **ID:** `GROWING_FAMILY`
* **Description:** Awarded when a user adopts a second animal, or more.
* **Technical condition:** The `adoption_applications` table updates to status `ACCEPTED` for an adopter who already has at least one accepted application.
* **Assignment mechanism:** Triggered by the same event handler as the first adoption badge, but validates that the adopter has a past record.

#### Unconditional love
* **ID:** `UNCONDITIONAL_LOVE`
* **Description:** Awarded when an adopter takes in an animal flagged with special needs or behavioral challenges.
* **Technical condition:** The `adoption_applications` table updates to status `ACCEPTED` for an animal whose `attributes` JSONB column includes a `special_needs` or `behavioral_challenges` flag set to true.
* **Assignment mechanism:** The adoption completion event checks the associated animal's attributes before assigning the badge.

#### Healing hands
* **ID:** `HEALING_HANDS`
* **Description:** Awarded when a foster user takes in an animal recovering from surgery or injury.
* **Technical condition:** A `foster_placements` record is created for an animal whose `attributes` JSONB column indicates a medical recovery status.
* **Assignment mechanism:** The foster placement creation event evaluates the animal's attributes and assigns the badge.

#### Endless love
* **ID:** `ENDLESS_LOVE`
* **Description:** Awarded to veteran fosters who have completed 10 or more foster placements.
* **Technical condition:** A user reaches 10 `COMPLETED` records in the `foster_placements` table.
* **Assignment mechanism:** When a foster placement transitions to completed status, the system counts the user's total completed placements and awards the badge on the tenth instance.

### Transport and sponsorship

#### Urgent express
* **ID:** `URGENT_EXPRESS`
* **Description:** Awarded when a transporter completes a run for a critical emergency case.
* **Technical condition:** A `transport_requests` record transitions to `DELIVERED` for a rescue case where the `ai_urgency_level` or `vet_urgency_level` is set to `CRITICAL`.
* **Assignment mechanism:** The transport completion event checks the linked rescue case urgency level before awarding the badge.

#### Paw patrol
* **ID:** `PAW_PATROL`
* **Description:** Awarded to frequent transporters who complete a high volume of runs.
* **Technical condition:** A transporter reaches 10 `DELIVERED` records in the `transport_requests` table.
* **Assignment mechanism:** The transport completion event tallies the transporter's total delivered runs and awards the badge upon reaching the threshold.

#### Always there
* **ID:** `ALWAYS_THERE`
* **Description:** Awarded to recurring sponsors who consistently support rescue cases.
* **Technical condition:** A sponsor completes their third distinct financial pledge in the `sponsorships` table.
* **Assignment mechanism:** The pledge fulfillment event counts the sponsor's total fulfilled sponsorships and issues the badge on the third instance.

#### Emergency funder
* **ID:** `EMERGENCY_FUNDER`
* **Description:** Awarded to sponsors who fund critical emergency or surgical cases.
* **Technical condition:** A `sponsorships` record is marked `FULFILLED` for a rescue case with a `CRITICAL` urgency level.
* **Assignment mechanism:** The pledge fulfillment event checks the urgency of the associated rescue case before issuing the badge.

### Community and stories

#### First responder
* **ID:** `FIRST_RESPONDER`
* **Description:** Awarded when a user posts their first rescue alert.
* **Technical condition:** A `community_posts` record of type `RESCUE` is created by a user with no previous rescue posts.
* **Assignment mechanism:** An event handler listens for post creation, checks the user's history for previous rescue posts, and assigns the badge.

#### Storyteller
* **ID:** `STORYTELLER`
* **Description:** Awarded for sharing 5 highlight posts with the community.
* **Technical condition:** A user reaches 5 `HIGHLIGHT` records in the `community_posts` table.
* **Assignment mechanism:** The post creation event counts the user's total highlight posts and awards the badge on the fifth instance.

#### Pawsitive updates
* **ID:** `PAWSITIVE_UPDATES`
* **Description:** Awarded to rescuers who provide 10 update posts on their cases.
* **Technical condition:** A user reaches 10 `UPDATE` records in the `community_posts` table.
* **Assignment mechanism:** The post creation event tallies the user's total update posts and awards the badge upon reaching the threshold.

#### Community voice
* **ID:** `COMMUNITY_VOICE`
* **Description:** Awarded when a user's post receives 50 likes.
* **Technical condition:** The `like_count` on a single `community_posts` record reaches 50.
* **Assignment mechanism:** The like event handler checks the post's total likes and awards the badge to the post author.

## Developer Usage: ReputationService Helper

The system encapsulates reputation logic into a centralized helper class `IReputationService`, located in the ASP.NET Core API at `HappyPaws.Application.Interfaces.IReputationService`.

### When to use
You must inject and call `IReputationService` whenever your CQRS Command Handler completes a domain action that triggers points or badges (e.g. Adoptions, Fosters, Transports, Posts, Likes).

### How to use
The service exposes highly-typed methods for each scenario. You do not manually calculate points or check badge conditions; you simply pass the required context IDs.

```csharp
public class AcceptAdoptionApplicationCommandHandler : IRequestHandler<AcceptAdoptionApplicationCommand, Result>
{
    private readonly IReputationService _reputation;

    public AcceptAdoptionApplicationCommandHandler(IReputationService reputation)
    {
        _reputation = reputation;
    }

    public async Task<Result> Handle(AcceptAdoptionApplicationCommand request, CancellationToken cancellationToken)
    {
        // ... (Accept the adoption logic) ...

        // Trigger reputation and badge calculation
        await _reputation.ProcessAdoptionAcceptedAsync(request.UserId, request.AnimalId, cancellationToken);
        
        // ... (Save changes) ...
    }
}
```

### Available API methods
* `ProcessAdoptionAcceptedAsync(userId, animalId)`
* `ProcessFosterPlacementCreatedAsync(userId, animalId)`
* `ProcessFosterPlacementCompletedAsync(userId)`
* `ProcessTransportDeliveredAsync(userId, rescueCaseId)`
* `ProcessSponsorshipFulfilledAsync(userId, rescueCaseId)`
* `ProcessPostCreatedAsync(userId, postType)`
* `ProcessPostLikedAsync(postAuthorId, postId)`
