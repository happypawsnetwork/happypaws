// Feature guide steps and screen-by-screen walkthroughs for Happy Paws Playbook
import type { UserStory } from "@/data/userStories";

export interface FeatureGuideStep {
  stepNumber: number;
  screenName: string;
  title: string;
  imagePath: string;
  imageAlt: string;
  description: string;
  primaryAction: {
    label: string;
    description: string;
    targetName?: string;
  };
  secondaryAction?: {
    label: string;
    description: string;
  };
  tips?: string[];
}

export const FEATURE_GUIDES: Record<string, FeatureGuideStep[]> = {
  'adopter-01': [
    {
      stepNumber: 1,
      screenName: 'Welcome to Happy Paws',
      title: 'Welcome and onboarding slides',
      imagePath: '/screenshots/adopter/adopter-01/step-01-onboarding.png',
      imageAlt: 'Onboarding carousel displaying the Happy Paws community illustration and welcome message',
      description: 'An overview of the application shown as illustrated slides, introducing pet adoption, rescue coordination, and community support in Sri Lanka.',
      primaryAction: {
        label: 'Continue',
        description: 'Click to advance past the introductory carousel and start the registration flow.',
        targetName: 'Continue button'
      },
      secondaryAction: {
        label: 'Sign in',
        description: 'Click if you already have an active account and want to sign in directly.'
      },
      tips: [
        'Swipe horizontally across the carousel to review additional feature highlights before proceeding.'
      ]
    },
    {
      stepNumber: 2,
      screenName: "Let's get started",
      title: 'Email address submission',
      imagePath: '/screenshots/adopter/adopter-01/step-02-email-entry.png',
      imageAlt: 'Email entry screen with input field and Send Code button',
      description: 'Initial registration step where you provide your email address to establish your user identity and receive a verification code.',
      primaryAction: {
        label: 'Send Code',
        description: 'Enter your email into the Enter your email field, then click to request a one-time verification passcode.',
        targetName: 'Send Code button'
      },
      secondaryAction: {
        label: 'Back',
        description: 'Click the back arrow in the top left corner to return to the onboarding slides.'
      },
      tips: [
        'Double-check for typos so the security passcode arrives in your inbox immediately.'
      ]
    },
    {
      stepNumber: 3,
      screenName: 'Verify your email address',
      title: 'Six-digit passcode verification',
      imagePath: '/screenshots/adopter/adopter-01/step-03-email-otp.png',
      imageAlt: 'Six-digit OTP input boxes with Verify button and countdown timer',
      description: 'Security verification screen where you confirm ownership of the submitted email address using a temporary six-digit passcode.',
      primaryAction: {
        label: 'Verify',
        description: 'Type the code received in your inbox into the six input boxes, then click to authenticate your address.',
        targetName: 'Verify button'
      },
      secondaryAction: {
        label: 'Resend code',
        description: 'Wait for the countdown timer to finish and click if you need a replacement verification code.'
      },
      tips: [
        'Check your spam or promotions folder if the verification email does not appear within 15 seconds.'
      ]
    },
    {
      stepNumber: 4,
      screenName: 'Tell us a bit about yourself',
      title: 'Profile details and password setup',
      imagePath: '/screenshots/adopter/adopter-01/step-04-profile-password.png',
      imageAlt: 'Profile completion form with name input and password fields',
      description: 'Profile setup form where you enter your full name and choose a secure password to protect your account.',
      primaryAction: {
        label: 'Create Account',
        description: 'Enter your full name in Your Name, enter a password in New Password, retype it in Confirm Password, then click to complete registration.',
        targetName: 'Create Account button'
      },
      secondaryAction: {
        label: 'Toggle visibility',
        description: 'Click the eye icon next to either password field to check your characters.'
      },
      tips: [
        'Choose a password with at least 8 characters, numbers, and symbols to keep your profile secure.'
      ]
    },
    {
      stepNumber: 5,
      screenName: "You're all set!",
      title: 'Registration confirmation',
      imagePath: '/screenshots/adopter/adopter-01/step-05-registration-success.png',
      imageAlt: 'Celebration screen with smiling puppy and kitten confirming account creation',
      description: 'Confirmation screen celebrating your completed registration, assigning your initial Adopter role, and welcoming you to the community.',
      primaryAction: {
        label: 'Go to Dashboard',
        description: 'Click to enter the home dashboard and begin browsing adoption listings and rescue cases.',
        targetName: 'Go to Dashboard button'
      },
      secondaryAction: {
        label: 'Additional roles',
        description: 'You are assigned the Adopter role by default, and you can unlock Foster, Transporter, or Sponsor roles anytime.'
      },
      tips: [
        'Explore the lifestyle matching quiz on your home screen to find animals best suited to your living environment.'
      ]
    }
  ],
  'adopter-02': [
    {
      stepNumber: 1,
      screenName: 'My Profile',
      title: 'Profile menu and verification entry',
      imagePath: '/screenshots/adopter/adopter-02/step-01-profile-menu.png',
      imageAlt: 'My Profile screen showing user details, active Adopter badge, and the Get Verified menu option',
      description: 'The profile overview displays your current account details, reputation score, and active roles. Access the Get Verified option from this menu to begin role elevation.',
      primaryAction: {
        label: 'Get Verified',
        description: 'Tap Get Verified to launch the identity verification workflow.',
        targetName: 'Get Verified menu item'
      },
      secondaryAction: {
        label: 'Edit profile',
        description: 'Tap the pencil icon in the top right corner to edit your display name and contact information.'
      },
      tips: [
        'Every account starts with the Adopter role upon registration, and you can unlock additional roles anytime.'
      ]
    },
    {
      stepNumber: 2,
      screenName: 'Identity verification',
      title: 'Identity verification overview',
      imagePath: '/screenshots/adopter/adopter-02/step-02-verification-intro.png',
      imageAlt: 'Identity verification intro screen showing trust badges, partner benefits, and required document guidelines',
      description: 'The introduction screen outlines why verification matters and what documents each role requires. Verification builds trust across the community and protects animals in rescue networks.',
      primaryAction: {
        label: 'Start verification',
        description: 'Tap Start verification to proceed to the role selection screen.',
        targetName: 'Start verification button'
      },
      secondaryAction: {
        label: 'Back',
        description: 'Tap the back arrow in the top left corner to cancel and return to your profile.'
      },
      tips: [
        'Review the document checklist in advance so you have your identification files ready on your device.'
      ]
    },
    {
      stepNumber: 3,
      screenName: 'Role selection',
      title: 'Target role selection',
      imagePath: '/screenshots/adopter/adopter-02/step-03-role-selection.png',
      imageAlt: 'Role selection dropdown displaying Foster as the selected community role with required document details',
      description: 'Choose the community role you want to apply for from the dropdown menu. The form updates dynamically to list the specific documents needed for that role.',
      primaryAction: {
        label: 'Begin verification',
        description: 'Select Foster from the dropdown list, then tap Begin verification to open the document upload form.',
        targetName: 'Begin verification button'
      },
      secondaryAction: {
        label: 'Role selector',
        description: 'Tap the dropdown menu to choose between Foster, Transporter, Sponsor, or Veterinarian.'
      },
      tips: [
        'Fostering requires a valid government-issued ID card or passport, and an optional proof of address.'
      ]
    },
    {
      stepNumber: 4,
      screenName: 'Upload Documents',
      title: 'Document upload requirements',
      imagePath: '/screenshots/adopter/adopter-02/step-04-document-requirements.png',
      imageAlt: 'Upload documents screen displaying required identity document and optional proof of address upload boxes',
      description: 'The upload screen displays designated slots for each required document. All uploaded files are transmitted securely and stored in encrypted storage.',
      primaryAction: {
        label: 'Tap to upload file',
        description: 'Tap the Government Identity Document slot to open your device file picker or camera.',
        targetName: 'Identity document upload slot'
      },
      secondaryAction: {
        label: 'Upload proof of address',
        description: 'Tap the optional Proof of Address slot if your current residential address differs from your official ID.'
      },
      tips: [
        'Accepted image formats include JPG and PNG. Provide clear, well-lit photos with legible text, and no glare.'
      ]
    },
    {
      stepNumber: 5,
      screenName: 'Upload Documents',
      title: 'Document attachment and preview',
      imagePath: '/screenshots/adopter/adopter-02/step-05-document-upload.png',
      imageAlt: 'Upload documents screen showing attached document previews with Replace and Remove actions',
      description: 'Once files are attached, visual preview cards confirm successful loading. You can replace or remove individual files before sending your submission.',
      primaryAction: {
        label: 'Submit Documents',
        description: 'Check that your document previews appear sharp and legible, then tap Submit Documents to send your request.',
        targetName: 'Submit Documents button'
      },
      secondaryAction: {
        label: 'Replace or Remove',
        description: 'Tap Replace to select an alternate file, or tap Remove to clear an attachment.'
      },
      tips: [
        'The Submit Documents button activates only after all mandatory document slots have valid attachments.'
      ]
    },
    {
      stepNumber: 6,
      screenName: 'Verification Submitted',
      title: 'Verification submission confirmation',
      imagePath: '/screenshots/adopter/adopter-02/step-06-submission-success.png',
      imageAlt: 'Verification submitted confirmation screen with estimated review timeline and notification information',
      description: 'A confirmation screen confirms that your application has been received. Our administration team reviews all pending applications within 24 to 48 hours.',
      primaryAction: {
        label: 'Back to Profile',
        description: 'Tap Back to Profile to return to your account menu while review takes place.',
        targetName: 'Back to Profile button'
      },
      secondaryAction: {
        label: 'Notification alerts',
        description: 'You will receive an in-app notification as soon as an administrator approves or updates your verification status.'
      },
      tips: [
        'You can continue browsing adoption listings, asking questions, and exploring community features while your verification is pending.'
      ]
    },
    {
      stepNumber: 7,
      screenName: 'Admin Verifications',
      title: 'Administrator review and approval',
      imagePath: '/screenshots/adopter/adopter-02/step-07-admin-review.png',
      imageAlt: 'Admin dashboard verifications table showing pending Foster application with document links and Approve button',
      description: 'Platform administrators review submitted credentials from the administrative web portal. Admins inspect the identity documents, check role qualifications, and grant approval.',
      primaryAction: {
        label: 'Approve',
        description: 'The administrator clicks Approve next to the pending request to grant the Foster role.',
        targetName: 'Approve button'
      },
      secondaryAction: {
        label: 'Document links',
        description: 'The administrator clicks GovernmentId or ProofOfAddress to inspect full-resolution files.'
      },
      tips: [
        'Admins can filter verification requests by role and review status to prioritize urgent applications.'
      ]
    },
    {
      stepNumber: 8,
      screenName: 'My Profile',
      title: 'Updated profile and role assignment',
      imagePath: '/screenshots/adopter/adopter-02/step-08-role-assigned.png',
      imageAlt: 'Updated My Profile screen displaying both Adopter and Foster role badges and the new Foster Care menu option',
      description: 'After administrative approval and a profile refresh, the new Foster role badge appears alongside Adopter. The navigation menu unlocks dedicated role features like Foster Care.',
      primaryAction: {
        label: 'Foster Care',
        description: 'Tap the newly unlocked Foster Care item to manage foster cases, shelter requests, and pet availability.',
        targetName: 'Foster Care menu item'
      },
      secondaryAction: {
        label: 'Role badges',
        description: 'View your active community badges directly under your profile name.'
      },
      tips: [
        'Pull down on the profile screen to refresh your claims and sync newly approved permissions immediately.'
      ]
    }
  ],
  'adopter-03': [
    {
      stepNumber: 1,
      screenName: 'Welcome to Happy Paws',
      title: 'Welcome screen and sign-in entry',
      imagePath: '/screenshots/adopter/adopter-03/step-01-welcome-screen.png',
      imageAlt: 'Welcome screen with pet rescue community illustration, Continue button, and Sign in link',
      description: 'The welcome screen introduces the Happy Paws community. If you already created an account during registration, use the direct sign-in link to skip the onboarding flow.',
      primaryAction: {
        label: 'Sign in',
        description: 'Click the Sign in link at the bottom of the screen to open the login form.',
        targetName: 'Sign in link'
      },
      secondaryAction: {
        label: 'Continue',
        description: 'Click Continue to begin registration if you do not have an account yet.'
      },
      tips: [
        'Swipe horizontally across the slides if you want to learn more about community features before signing in.'
      ]
    },
    {
      stepNumber: 2,
      screenName: 'Welcome back',
      title: 'Account credentials entry',
      imagePath: '/screenshots/adopter/adopter-03/step-02-credentials-entry.png',
      imageAlt: 'Login form with email field, masked password field with visibility toggle, and Continue button',
      description: 'Enter your registered email address and password to verify your account. The mobile app sends these credentials to the backend authentication endpoint to issue a role-scoped session token.',
      primaryAction: {
        label: 'Continue',
        description: 'Enter your email address and password, then click Continue to sign in.',
        targetName: 'Continue button'
      },
      secondaryAction: {
        label: 'Forgot password?',
        description: 'Click Forgot password? below the password field to request a password reset link if you cannot access your account.'
      },
      tips: [
        'Click the eye icon on the right side of the password field to verify your characters before submitting.',
        'If you need a new account, tap Sign up at the bottom of the form to switch to registration.'
      ]
    },
    {
      stepNumber: 3,
      screenName: 'Community feed',
      title: 'Community feed and navigation',
      imagePath: '/screenshots/adopter/adopter-03/step-03-community-feed.png',
      imageAlt: 'Community feed showing pet adoption cards, category filters, and bottom navigation tabs',
      description: 'After a successful sign-in, the community feed displays nearby adoption listings, urgent rescue updates, and shared pet stories. The bottom navigation bar provides instant access to the rescue map, report publishing, messages, and profile settings.',
      primaryAction: {
        label: 'Browse feed',
        description: 'Scroll through the main feed or tap category chips like Rescue, Update, or Find Home to filter posts.',
        targetName: 'Category filter chips'
      },
      secondaryAction: {
        label: 'Bottom navigation',
        description: 'Tap any bottom tab to visit the map view, report an urgent rescue case, check your direct messages, or manage your account.'
      },
      tips: [
        'Tap the notification bell in the top bar to inspect instant alerts about nearby rescues, application updates, and pet activity.'
      ]
    }
  ],
  'adopter-04': [
    {
      stepNumber: 1,
      screenName: 'My Profile',
      title: 'Profile overview and verification entry',
      imagePath: '/screenshots/adopter/adopter-04/step-01-profile-menu.png',
      imageAlt: 'My Profile screen displaying user details, reputation score, adopter badge without verification checkmark, and Get Verified menu option',
      description: 'Your profile displays your personal details, current reputation score, and assigned community roles. When you first register, your Adopter role starts unverified. Tap Get Verified to open the identity verification flow and earn your verified badge.',
      primaryAction: {
        label: 'Get Verified',
        description: 'Tap Get Verified to launch the identity verification workflow.',
        targetName: 'Get Verified menu item'
      },
      secondaryAction: {
        label: 'Edit profile',
        description: 'Tap the pencil icon in the top right corner to review or update your display name and basic details.'
      },
      tips: [
        'Verifying your identity unlocks unrestricted messaging, direct rescue case submissions, and adoption applications.'
      ]
    },
    {
      stepNumber: 2,
      screenName: 'Identity verification',
      title: 'Identity verification overview',
      imagePath: '/screenshots/adopter/adopter-04/step-02-verification-overview.png',
      imageAlt: 'Identity verification introductory screen detailing trust badges, partner roles, and required documents',
      description: 'The introductory screen explains how verification protects pets and community members across Sri Lanka. It outlines the benefits of verified badges and lists the identity documentation required for each role.',
      primaryAction: {
        label: 'Start verification',
        description: 'Tap Start verification to begin your verification application.',
        targetName: 'Start verification button'
      },
      secondaryAction: {
        label: 'Back',
        description: 'Tap the back arrow in the top left corner to exit and return to your profile overview.'
      },
      tips: [
        'Have a valid National Identity Card (NIC) or passport ready on your device before starting.'
      ]
    },
    {
      stepNumber: 3,
      screenName: 'Home address required',
      title: 'Address completion prompt',
      imagePath: '/screenshots/adopter/adopter-04/step-03-address-required-prompt.png',
      imageAlt: 'Modal dialog indicating that home address, province, and city must be provided before continuing verification',
      description: 'If your account profile does not yet have complete residential details, this modal prompt appears. Providing your address, province, and city helps the team confirm your local jurisdiction and geographic rescue area.',
      primaryAction: {
        label: 'Go to settings',
        description: 'Tap Go to settings to fill out your residential address, province, and city.',
        targetName: 'Go to settings button'
      },
      secondaryAction: {
        label: 'Cancel',
        description: 'Tap Cancel to dismiss the prompt and return to the verification overview screen.'
      },
      tips: [
        'Once you save your address in settings, you can return immediately to continue identity verification.'
      ]
    },
    {
      stepNumber: 4,
      screenName: 'Role selection',
      title: 'Adopter role selection',
      imagePath: '/screenshots/adopter/adopter-04/step-04-role-selection.png',
      imageAlt: 'Identity verification role selector showing Adopter selected from the dropdown with required document details',
      description: 'Select the Adopter role from the dropdown menu to verify your primary account tier. Roles you already verified cannot be selected again, keeping your application focused on unverified permissions.',
      primaryAction: {
        label: 'Begin verification',
        description: 'Choose Adopter in the dropdown, then tap Begin verification to advance to document upload.',
        targetName: 'Begin verification button'
      },
      secondaryAction: {
        label: 'Role selector',
        description: 'Tap the dropdown menu to inspect requirements for other community roles like Foster, Transporter, Sponsor, or Veterinarian.'
      },
      tips: [
        'Verifying the Adopter role requires a valid government-issued ID, with proof of address being optional.'
      ]
    },
    {
      stepNumber: 5,
      screenName: 'Upload Documents',
      title: 'Identity document attachment',
      imagePath: '/screenshots/adopter/adopter-04/step-05-document-upload.png',
      imageAlt: 'Document upload screen with preview of uploaded government identity card, replace and remove actions, and optional address proof slot',
      description: 'Attach a clear photo or scan of your government identity document, such as a National Identity Card (NIC) or passport. All uploaded files travel over encrypted channels and store safely in protected cloud storage.',
      primaryAction: {
        label: 'Submit Documents',
        description: 'Confirm that your identity document preview is clear and legible, then tap Submit Documents to send your files.',
        targetName: 'Submit Documents button'
      },
      secondaryAction: {
        label: 'Replace or Remove',
        description: 'Tap Replace to select a sharper photo, or tap Remove to discard the current attachment.'
      },
      tips: [
        'Submit clear photos with all four corners visible, legible text, and zero flash glare to avoid verification delays.',
        'Add proof of address only if your current residence differs from the address printed on your official ID.'
      ]
    },
    {
      stepNumber: 6,
      screenName: 'Verification Submitted',
      title: 'Application submission confirmation',
      imagePath: '/screenshots/adopter/adopter-04/step-06-submission-success.png',
      imageAlt: 'Confirmation screen with green checkmark indicating successful verification submission and review timeline',
      description: 'A confirmation screen confirms that your application reached our review queue. Platform administrators inspect submitted documents within 24 to 48 hours.',
      primaryAction: {
        label: 'Back to Profile',
        description: 'Tap Back to Profile to return to your account menu while administrative review takes place.',
        targetName: 'Back to Profile button'
      },
      secondaryAction: {
        label: 'In-app notifications',
        description: 'The app notifies you as soon as an administrator approves your identity verification.'
      },
      tips: [
        'You can continue browsing adoption listings, asking questions, and exploring community stories while your review is pending.'
      ]
    },
    {
      stepNumber: 7,
      screenName: 'Verifications',
      title: 'Administrator review and approval',
      imagePath: '/screenshots/adopter/adopter-04/step-07-admin-review.png',
      imageAlt: 'Web administration portal showing pending Adopter verification with GovernmentId document link and Approve button',
      description: 'Platform administrators review submitted identity requests from the web administration dashboard. Admins examine the uploaded government ID against user account records before granting approval.',
      primaryAction: {
        label: 'Approve',
        description: 'The administrator reviews the attached GovernmentId document and clicks Approve to verify the account.',
        targetName: 'Approve button'
      },
      secondaryAction: {
        label: 'GovernmentId',
        description: 'Click the GovernmentId document link to inspect full-resolution identity documents in a secure viewer.'
      },
      tips: [
        'Admins can filter records by role and review status to locate pending requests quickly.'
      ]
    },
    {
      stepNumber: 8,
      screenName: 'My Profile',
      title: 'Verified profile with trust badge',
      imagePath: '/screenshots/adopter/adopter-04/step-08-verified-profile.png',
      imageAlt: 'Updated My Profile screen displaying a blue verified checkmark badge next to the user name and active Adopter role',
      description: 'After administrator approval, a blue verification badge appears directly next to your profile name. This checkmark lets the entire community know that your identity is verified, boosting your credibility in adoption and rescue requests.',
      primaryAction: {
        label: 'Pull to refresh',
        description: 'Swipe down on the profile screen to fetch updated user claims and see your verified status immediately.',
        targetName: 'Profile screen'
      },
      secondaryAction: {
        label: 'Verified checkmark',
        description: 'View the blue verification badge prominently positioned beside your name across community feeds and comments.'
      },
      tips: [
        'With your Adopter role verified, you can now apply for pets and publish rescue cases with full community trust.'
      ]
    }
  ],
  'adopter-05': [
    {
      stepNumber: 1,
      screenName: 'My Profile',
      title: 'Profile menu and lifestyle entry',
      imagePath: '/screenshots/adopter/adopter-05/step-01-profile-menu.png',
      imageAlt: 'My Profile screen showing user details, reputation score, and the Lifestyle Profile menu option',
      description: 'The profile screen gathers your account preferences, active roles, and community tools. Tap Lifestyle Profile to begin or adjust your pet compatibility questionnaire.',
      primaryAction: {
        label: 'Lifestyle Profile',
        description: 'Tap the Lifestyle Profile item to open the questionnaire.',
        targetName: 'Lifestyle Profile menu item'
      },
      secondaryAction: {
        label: 'Edit profile',
        description: 'Tap the pencil icon in the top right corner to edit your public name and bio.'
      },
      tips: [
        'Completing your lifestyle profile helps the matching algorithm suggest pets well-suited to your daily routine, living environment, and experience level.'
      ]
    },
    {
      stepNumber: 2,
      screenName: 'Lifestyle profile',
      title: 'Living arrangements and preferences',
      imagePath: '/screenshots/adopter/adopter-05/step-02-lifestyle-form.png',
      imageAlt: 'Lifestyle profile questionnaire showing dwelling options, outdoor space toggles, and Save lifestyle profile action',
      description: 'Select the home dwelling type that best matches your residence, indicate outdoor yard space, and set your activity preferences. Once you finish answering the questions, tap Save lifestyle profile to update your account and refresh matching recommendations.',
      primaryAction: {
        label: 'Save lifestyle profile',
        description: 'Select your dwelling type, configure your outdoor environment, and tap Save lifestyle profile to store your answers.',
        targetName: 'Save lifestyle profile button'
      },
      secondaryAction: {
        label: 'Back',
        description: 'Tap the back arrow in the top left corner to exit without saving changes.'
      },
      tips: [
        'You can return and update your answers anytime your living arrangements, work hours, or pet experience change.',
        'Be accurate about your space and activity level so the system pairs you with animals that thrive in your setting.'
      ]
    }
  ],
  'adopter-06': [
    {
      stepNumber: 1,
      screenName: 'Search and explore',
      title: 'Search exploration landing view',
      imagePath: '/screenshots/adopter/adopter-06/step-01-search-explore.png',
      imageAlt: 'Search screen showing search text bar, quick filter chips for dogs, cats, find home, and rescue, with suggestion cards below',
      description: 'The search screen offers a centralized discovery hub for all animals listed across Happy Paws. You can use the search bar, tap quick filter chips, or pick one of the exploration suggestion cards to start browsing immediately.',
      primaryAction: {
        label: 'Search animals, breeds, places...',
        description: 'Tap the search field to enter keywords or animal names.',
        targetName: 'Search input field'
      },
      secondaryAction: {
        label: 'Quick filter chips',
        description: 'Tap any category chip such as Dogs, Cats, Find Home, or Rescue to filter the listings in one tap.'
      },
      tips: [
        'Search results are completely unconstrained by your lifestyle questionnaire, allowing you to browse any pet across Sri Lanka regardless of your profile.'
      ]
    },
    {
      stepNumber: 2,
      screenName: 'Search results',
      title: 'Live debounced keyword search',
      imagePath: '/screenshots/adopter/adopter-06/step-02-keyword-search.png',
      imageAlt: 'Search screen showing query text Sunny and matching adoption listing post cards with animal details and location',
      description: 'Typing in the search bar triggers a real-time debounced query that checks animal names, breeds, descriptions, and locations. Matching results appear immediately as scrollable cards with direct adoption and rescue details.',
      primaryAction: {
        label: 'Clear search',
        description: 'Tap the clear icon to wipe the current search text and return to the exploration view.',
        targetName: 'Clear icon button'
      },
      secondaryAction: {
        label: 'View post details',
        description: 'Tap any animal post card to inspect full photos, author contact, and adoption application options.'
      },
      tips: [
        'The search bar waits 400 milliseconds after you stop typing before sending the query, saving network requests while delivering snappy results.'
      ]
    },
    {
      stepNumber: 3,
      screenName: 'Search filters',
      title: 'Multi-criteria filter modal',
      imagePath: '/screenshots/adopter/adopter-06/step-03-filter-modal-options.png',
      imageAlt: 'Filter bottom sheet modal showing options for listing type, species selection, color-coded urgency levels, and location input',
      description: 'The filter modal allows precise filtering across listing types, animal species, color-coded urgency levels, and location cities. An informative note reminds you that searches are independent of matching engine recommendations.',
      primaryAction: {
        label: 'Apply filters',
        description: 'Tap Apply filters to submit your selected criteria and refresh the search feed.',
        targetName: 'Apply filters button'
      },
      secondaryAction: {
        label: 'Reset all',
        description: 'Tap Reset all in the top right corner to clear every active filter back to default.'
      },
      tips: [
        'Urgency filtering helps responders and adopters quickly spot critical animals that need response within hours or days.',
        'You can enter a custom species if looking for animals outside common domestic pets.'
      ]
    },
    {
      stepNumber: 4,
      screenName: 'Filtered listings',
      title: 'Independent filtered listings with active tags',
      imagePath: '/screenshots/adopter/adopter-06/step-04-filtered-results-independent.png',
      imageAlt: 'Search screen displaying active filter tags row with dismiss buttons and filtered animal post cards below',
      description: 'The feed displays animals matching your combined filters. Active filter tags appear below the search bar with single-tap remove buttons. Matching engine recommendation badges appear informatively on cards that fit your profile, but non-recommended animals remain fully discoverable.',
      primaryAction: {
        label: 'Dismiss active filter',
        description: 'Tap the cross on any active tag to remove that specific filter and refresh results instantly.',
        targetName: 'Filter dismiss tag'
      },
      secondaryAction: {
        label: 'Clear all',
        description: 'Tap Clear all to reset all active filters at once.'
      },
      tips: [
        'The green Recommended chip highlights pets that match your lifestyle profile, while non-matching pets are still visible so your options are never restricted.'
      ]
    },
    {
      stepNumber: 5,
      screenName: 'No animals found',
      title: 'Empty state and filter reset',
      imagePath: '/screenshots/adopter/adopter-06/step-05-empty-state-reset.png',
      imageAlt: 'Empty state illustration displaying No animals found message with Clear all filters button',
      description: 'When a query or filter combination produces no matching animals, a clear empty state explains that no animals met the criteria. A prominent recovery button allows you to clear all filters in one tap.',
      primaryAction: {
        label: 'Clear all filters',
        description: 'Tap Clear all filters to reset your search and return to the exploration feed.',
        targetName: 'Clear all filters button'
      },
      secondaryAction: {
        label: 'Back',
        description: 'Tap the back arrow to return to the community feed.'
      },
      tips: [
        'If you find no results, broaden your location or switch urgency to All to see a wider selection of animals.'
      ]
    }
  ]
};

export function getFeatureGuide(storyId: string): FeatureGuideStep[] | undefined {
  return FEATURE_GUIDES[storyId.toLowerCase()];
}

export function hasFeatureGuide(storyId: string): boolean {
  const guide = getFeatureGuide(storyId);
  return Boolean(guide && guide.length > 0);
}

export function hasStoryOverview(story?: UserStory | null): boolean {
  if (!story) return false;
  return Boolean(
    story.userStory &&
    story.userStory.trim().length > 0 &&
    story.description &&
    story.description.trim().length > 0
  );
}

export interface StoryStatus {
  isPending: boolean;
  hasOverview: boolean;
  hasGuide: boolean;
  reason?: string;
}

export function getStoryStatus(story?: UserStory | null): StoryStatus {
  const hasOverview = hasStoryOverview(story);
  const hasGuide = story ? hasFeatureGuide(story.id) : false;
  const isPending = !hasOverview || !hasGuide;

  let reason: string | undefined;
  if (!hasOverview && !hasGuide) {
    reason = "Pending: Story overview and feature guide are missing";
  } else if (!hasOverview) {
    reason = "Pending: Story overview is missing";
  } else if (!hasGuide) {
    reason = "Pending: Feature guide is missing";
  }

  return { isPending, hasOverview, hasGuide, reason };
}

