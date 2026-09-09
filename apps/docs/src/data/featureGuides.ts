// Feature guide steps and screen-by-screen walkthroughs for Happy Paws Playbook

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
  ]
};

export function getFeatureGuide(storyId: string): FeatureGuideStep[] | undefined {
  return FEATURE_GUIDES[storyId.toLowerCase()];
}
