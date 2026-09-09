// OpenAPI specification parser and utilities for Happy Paws Playbook
import specData from './openapi.json';

export interface ApiParameter {
  name: string;
  in: 'path' | 'query' | 'header' | 'cookie';
  description?: string;
  required?: boolean;
  schema?: {
    type?: string;
    format?: string;
    default?: unknown;
    nullable?: boolean;
  };
}

export interface ApiRequestBody {
  description?: string;
  required?: boolean;
  content?: Record<
    string,
    {
      schema?: Record<string, unknown>;
    }
  >;
}

export interface ApiResponse {
  description?: string;
  content?: Record<
    string,
    {
      schema?: Record<string, unknown>;
    }
  >;
}

export interface ApiOperation {
  id: string; // anchor id
  path: string;
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  operationId: string;
  summary: string;
  description: string;
  tags: string[];
  category: string;
  parameters: ApiParameter[];
  requestBody?: ApiRequestBody;
  responses: Record<string, ApiResponse>;
}

export function getEndpointAnchor(method: string, path: string): string {
  const normalizedMethod = method.toLowerCase();
  const normalizedPath = path
    .replace(/[{}]/g, '')
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .toLowerCase();
  return `${normalizedMethod}-${normalizedPath}`;
}

export function parseEndpointString(ep: string): { method: string; path: string; anchor: string } {
  const parts = ep.trim().split(/\s+/);
  let method = 'GET';
  let path = ep.trim();

  if (parts.length >= 2 && ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].includes(parts[0].toUpperCase())) {
    method = parts[0].toUpperCase();
    path = parts.slice(1).join(' ');
  }

  return {
    method,
    path,
    anchor: getEndpointAnchor(method, path)
  };
}

export function getMethodBadgeClasses(method: string): {
  badge: string;
  pill: string;
  text: string;
  border: string;
  bg: string;
} {
  const m = method.toUpperCase();
  switch (m) {
    case 'GET':
      return {
        badge: 'bg-emerald-50 text-emerald-700 border-emerald-200',
        pill: 'bg-emerald-600 text-white',
        text: 'text-emerald-700',
        border: 'border-emerald-300',
        bg: 'bg-emerald-50/70'
      };
    case 'POST':
      return {
        badge: 'bg-blue-50 text-blue-700 border-blue-200',
        pill: 'bg-blue-600 text-white',
        text: 'text-blue-700',
        border: 'border-blue-300',
        bg: 'bg-blue-50/70'
      };
    case 'PUT':
      return {
        badge: 'bg-amber-50 text-amber-700 border-amber-200',
        pill: 'bg-amber-600 text-white',
        text: 'text-amber-700',
        border: 'border-amber-300',
        bg: 'bg-amber-50/70'
      };
    case 'PATCH':
      return {
        badge: 'bg-purple-50 text-purple-700 border-purple-200',
        pill: 'bg-purple-600 text-white',
        text: 'text-purple-700',
        border: 'border-purple-300',
        bg: 'bg-purple-50/70'
      };
    case 'DELETE':
      return {
        badge: 'bg-rose-50 text-rose-700 border-rose-200',
        pill: 'bg-rose-600 text-white',
        text: 'text-rose-700',
        border: 'border-rose-300',
        bg: 'bg-rose-50/70'
      };
    default:
      return {
        badge: 'bg-slate-50 text-slate-700 border-slate-200',
        pill: 'bg-slate-600 text-white',
        text: 'text-slate-700',
        border: 'border-slate-300',
        bg: 'bg-slate-50/70'
      };
  }
}

function deriveCategory(path: string, tags: string[]): string {
  if (path.startsWith('/api/v1/community/transport-tasks')) return 'Transport tasks';
  if (path.startsWith('/api/v1/community/sponsorships')) return 'Sponsorships';
  if (path.startsWith('/api/v1/community/rescue-triage')) return 'AI rescue triage';
  if (path.startsWith('/api/v1/community/posts')) return 'Community and rescue posts';
  if (path.startsWith('/api/v1/community/my-rescues')) return 'Community and rescue posts';
  if (path.startsWith('/api/v1/admin/posts')) return 'Admin community posts';
  if (path.startsWith('/api/v1/admin/rescues')) return 'Admin rescues and live map';
  if (path.startsWith('/api/admin/analytics')) return 'Admin analytics';
  if (path.startsWith('/api/admin/users')) return 'Admin user management';
  if (path.startsWith('/api/admin/verifications')) return 'Admin KYC verifications';
  if (path.startsWith('/api/auth/admin')) return 'Admin authentication';
  if (path.startsWith('/api/auth')) return 'Authentication and accounts';
  if (path.startsWith('/api/messaging')) return 'Private in-app messaging';
  if (path.startsWith('/api/profile')) return 'User profile and lifestyle';
  if (path.startsWith('/api/verification')) return 'Identity verification';

  if (tags && tags.length > 0 && tags[0] !== 'HappyPaws.Api') {
    return tags[0];
  }

  return 'General API';
}

interface RawOpenApiSpec {
  openapi: string;
  info: {
    title: string;
    version: string;
    description?: string;
  };
  paths: Record<
    string,
    Record<
      string,
      {
        operationId?: string;
        summary?: string;
        description?: string;
        tags?: string[];
        parameters?: ApiParameter[];
        requestBody?: ApiRequestBody;
        responses?: Record<string, ApiResponse>;
      }
    >
  >;
  components?: {
    schemas?: Record<string, unknown>;
  };
}

const rawSpec = specData as unknown as RawOpenApiSpec;

export const openApiSpecInfo = {
  title: rawSpec.info?.title || 'HappyPaws API',
  version: rawSpec.info?.version || '1.0.0',
  openapi: rawSpec.openapi || '3.1.1'
};

export const allApiOperations: ApiOperation[] = [];

for (const [path, methods] of Object.entries(rawSpec.paths || {})) {
  for (const [methodKey, op] of Object.entries(methods)) {
    const method = methodKey.toUpperCase() as ApiOperation['method'];
    const tags = op.tags || [];
    const category = deriveCategory(path, tags);
    const id = getEndpointAnchor(method, path);

    allApiOperations.push({
      id,
      path,
      method,
      operationId: op.operationId || id,
      summary: op.summary || `${method} ${path}`,
      description: op.description || '',
      tags,
      category,
      parameters: op.parameters || [],
      requestBody: op.requestBody,
      responses: op.responses || {}
    });
  }
}

export const apiCategories = Array.from(new Set(allApiOperations.map(op => op.category))).sort();
