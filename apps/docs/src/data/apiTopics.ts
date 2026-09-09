// API specification topics and domain groupings for Happy Paws Playbook
import { allApiOperations, type ApiOperation } from './openApiUtils';

export interface ApiTopic {
  id: string;
  name: string;
  description: string;
  iconName: string;
  category: string;
  endpoints: ApiOperation[];
  endpointCount: number;
}

export interface ApiTopicDefinition {
  id: string;
  name: string;
  description: string;
  iconName: string;
  category: string;
}

export const API_TOPIC_DEFINITIONS: ApiTopicDefinition[] = [
  {
    id: 'identity-verification',
    name: 'Identity verification',
    description: 'Citizen identity verification, National Identity Card uploads, and status tracking.',
    iconName: 'ShieldCheck',
    category: 'Identity verification'
  },
  {
    id: 'authentication-accounts',
    name: 'Authentication and accounts',
    description: 'Mobile user registration, one-time passcode verification, JWT sessions, and password recovery.',
    iconName: 'KeyRound',
    category: 'Authentication and accounts'
  },
  {
    id: 'user-profile-lifestyle',
    name: 'User profile and lifestyle',
    description: 'Profile management, avatar uploads, lifestyle questionnaires, and session audits.',
    iconName: 'User',
    category: 'User profile and lifestyle'
  },
  {
    id: 'community-rescue-posts',
    name: 'Community and rescue posts',
    description: 'Animal rescue reporting, adoption listings, comments, reactions, and post boosts.',
    iconName: 'Users',
    category: 'Community and rescue posts'
  },
  {
    id: 'ai-rescue-triage',
    name: 'AI rescue triage',
    description: 'Automated image classification, injury assessment, and triage severity prediction.',
    iconName: 'Sparkles',
    category: 'AI rescue triage'
  },
  {
    id: 'transport-tasks',
    name: 'Transport tasks',
    description: 'Volunteer animal transport coordination, route tracking, pickup, and delivery.',
    iconName: 'Truck',
    category: 'Transport tasks'
  },
  {
    id: 'sponsorships',
    name: 'Sponsorships',
    description: 'Medical sponsorship campaigns, recurring pledges, and donation tracking.',
    iconName: 'Coins',
    category: 'Sponsorships'
  },
  {
    id: 'private-messaging',
    name: 'Private in-app messaging',
    description: 'Direct conversations between adopters, rescuers, and staff, with user safety controls.',
    iconName: 'MessageSquare',
    category: 'Private in-app messaging'
  },
  {
    id: 'admin-authentication',
    name: 'Admin authentication',
    description: 'Staff portal sign-in, two-factor authentication setup, and session refresh.',
    iconName: 'Lock',
    category: 'Admin authentication'
  },
  {
    id: 'admin-user-management',
    name: 'Admin user management',
    description: 'User administration, role upgrades, account suspensions, and reactivations.',
    iconName: 'UserCheck',
    category: 'Admin user management'
  },
  {
    id: 'admin-kyc-verifications',
    name: 'Admin KYC verifications',
    description: 'Reviewing citizen identity submissions, approving verified accounts, and handling rejections.',
    iconName: 'FileCheck',
    category: 'Admin KYC verifications'
  },
  {
    id: 'admin-community-posts',
    name: 'Admin community posts',
    description: 'Moderating public community posts, reviewing reports, and managing violations.',
    iconName: 'ShieldAlert',
    category: 'Admin community posts'
  },
  {
    id: 'admin-rescues-live-map',
    name: 'Admin rescues and live map',
    description: 'Emergency rescue incident monitoring, live geospatial tracking, and field dispatch.',
    iconName: 'MapPin',
    category: 'Admin rescues and live map'
  },
  {
    id: 'admin-analytics',
    name: 'Admin analytics',
    description: 'Platform metrics, rescue success statistics, and operational telemetry.',
    iconName: 'BarChart3',
    category: 'Admin analytics'
  }
];

export function getApiTopics(): ApiTopic[] {
  return API_TOPIC_DEFINITIONS.map(def => {
    const endpoints = allApiOperations.filter(op => op.category === def.category);
    return {
      ...def,
      endpoints,
      endpointCount: endpoints.length
    };
  });
}

export const API_TOPICS = getApiTopics();

export function getApiTopic(topicId: string): ApiTopic | undefined {
  const normalized = topicId.toLowerCase().trim();
  return API_TOPICS.find(t => t.id === normalized || t.name.toLowerCase() === normalized);
}

export function getTopicForEndpoint(anchorOrId: string): ApiTopic | undefined {
  const normalized = anchorOrId.replace(/^#/, '').toLowerCase().trim();
  return API_TOPICS.find(t => t.endpoints.some(ep => ep.id.toLowerCase() === normalized));
}
