# Web coding style (Next.js 16 and React 19)

These rules apply to all TypeScript, React, and Tailwind CSS code written for `happypaws-web` (`apps/web/`). Following them maintains high performance, security, accessibility, and architectural consistency across the web application.

## Architecture and rendering strategy

Adopt a server-first architecture using the Next.js App Router.
- **Server Components by default**: Keep all pages and layout components as React Server Components (RSC). Server Components fetch data directly, execute zero client-side JavaScript, improve initial page load times, and boost search engine ranking.
- **Leaf Client Components**: Mark components with `'use client'` only when they require user interactivity (such as event handlers, React hooks, or browser APIs). Push Client Components as far down the component tree as possible to minimize JavaScript bundle sizes.
- **Streaming with Suspense**: Wrap slow or dynamic data fetches inside `<Suspense fallback={<Skeleton />}>` boundaries to render the static shell instantly while streaming dynamic sections to the browser.
- **Feature organization**: Group files by feature (such as `app/(public)/adoptions/` or `app/admin/rescues/`) rather than splitting them into broad technical folders.

## Server Actions and data mutations

Treat Server Actions as public HTTP endpoints.
- **Always authenticate**: Verify user session and role authorization inside the Server Action before executing mutations. Never trust client-sent claims without verification.
- **Always validate inputs**: Parse incoming parameters with Zod schemas to reject malformed data before touching downstream services.
- **Use React 19 action hooks**: Manage form submission state, pending transitions, and error messages using `useActionState` and `useFormStatus` instead of manual `useState` and `useEffect` tracking.
- **Optimistic UI**: Use `useOptimistic` to provide instant user feedback on critical actions (such as favoriting an animal or liking a post) while the network request resolves in the background.

## Route protection and middleware

Protect restricted areas (like `/admin/*` and volunteer dashboards) at the edge using Next.js Middleware (`middleware.ts`).
- Read authenticated user session tokens from secure HttpOnly cookies.
- Verify user roles before route execution begins. If a user lacks the required role, immediately redirect them to the login page or return a 403 Forbidden status.
- Avoid heavy database queries or third-party SDK calls inside Middleware. Keep edge logic lightweight and fast.

## Performance and media optimization

- **Images**: Always use the `next/image` component for animal photos and avatars. Specify explicit `width`, `height`, and `sizes` attributes to prevent Cumulative Layout Shift (CLS) and enable automatic WebP/AVIF format conversion.
- **Fonts**: Load fonts using `next/font/google` with `display: 'swap'` to eliminate layout shifts and reduce external network round-trips.
- **Bundle hygiene**: Avoid barrel export imports that pull in unnecessary dependencies. Import icons and utilities directly from their specific submodules.

## TypeScript and naming conventions

- Enable strict TypeScript checking. Never use `any`. Always declare explicit interfaces, types, or Zod inferred types for component props and state.
- Use PascalCase for React component names and component file names (for example, `AnimalCard.tsx` and `RescueReportModal.tsx`).
- Use camelCase for utility functions, custom hooks, and variables (for example, `useGeolocation.ts` and `formatDate.ts`).
- Prefix custom React hooks with `use` (for example, `useAnimalFilter.ts`).
- Use kebab-case for route directory names (for example, `app/(public)/rescue-operations/`).

## Security and accessibility

- **Cross-Site Scripting (XSS)**: Never use `dangerouslySetInnerHTML` with unverified or user-supplied content. Sanitize all markdown or HTML rendering.
- **Secrets**: Store sensitive API keys and tokens in server-only environment variables. Never prefix private credentials with `NEXT_PUBLIC_`.
- **Semantic HTML**: Use proper HTML tags (`<main>`, `<section>`, `<article>`, `<header>`, `<nav>`, `<button>`) rather than building everything with generic `<div>` elements.
- **Accessibility (a11y)**: Provide descriptive `alt` text for all images, include explicit `aria-label` attributes on icon buttons, and maintain high color contrast ratios that meet WCAG 2.1 AA standards.

## Documentation and comments

Explain why the code exists, not what it does. Write comments that clarify edge cases, security checks, and non-obvious React rendering choices. Omit comments that restate obvious JSX syntax.

When writing comments or documentation, adhere strictly to these rules:
- Write in plain, direct language.
- Do not use em dashes. Use commas, parentheses, or short sentences instead.
- Do not use semicolons in prose or comments.
- Use the Oxford comma in all lists.
- Use sentence case for all headings and labels.
- Avoid filler words like "utilize", "leverage", "ensure", and "streamline".

---

## Example scenarios

Use these code snippets as blueprints when writing or refactoring frontend web components.

### 1. Server Component page with streaming and Suspense

This scenario shows a public animal adoption directory. It demonstrates data fetching inside a Server Component, error boundary patterns, and streaming with Suspense.

```tsx
import { Suspense } from 'react';
import Image from 'next/image';
import Link from 'next/link';

interface Animal {
  id: string;
  name: string;
  breed: string;
  ageYears: number;
  photoUrl: string;
  urgencyLevel: string;
}

// Fetch public animals directly on the server without shipping client JavaScript
async function getAnimals(): Promise<Animal[]> {
  const apiUrl = process.env.API_BASE_URL || 'http://localhost:5000';
  
  // Revalidate public listing cache every 60 seconds to balance freshness and server load
  const response = await fetch(`${apiUrl}/api/v1/animals`, {
    next: { revalidate: 60 },
  });

  if (!response.ok) {
    throw new Error('Failed to load animal listings from the backend service.');
  }

  return response.json();
}

function AnimalCardSkeleton() {
  return (
    <div className="animate-pulse rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="h-48 w-full rounded-xl bg-slate-200" />
      <div className="mt-4 h-6 w-3/4 rounded bg-slate-200" />
      <div className="mt-2 h-4 w-1/2 rounded bg-slate-200" />
    </div>
  );
}

async function AnimalGrid() {
  const animals = await getAnimals();

  if (animals.length === 0) {
    return (
      <div className="rounded-2xl border border-dashed border-slate-300 p-12 text-center">
        <p className="text-lg font-medium text-slate-700">No animals currently available for adoption.</p>
        <p className="mt-1 text-sm text-slate-500">Please check back soon or report a rescue case in need.</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
      {animals.map((animal) => (
        <article
          key={animal.id}
          className="group overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md"
        >
          <div className="relative h-56 w-full overflow-hidden bg-slate-100">
            <Image
              src={animal.photoUrl}
              alt={`Photo of ${animal.name}, a ${animal.breed}`}
              fill
              sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
              className="object-cover transition duration-300 group-hover:scale-105"
            />
          </div>
          <div className="p-5">
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-900">{animal.name}</h2>
              <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-medium text-emerald-700">
                {animal.ageYears} {animal.ageYears === 1 ? 'year' : 'years'} old
              </span>
            </div>
            <p className="mt-1 text-sm text-slate-600">{animal.breed}</p>
            <Link
              href={`/adoptions/${animal.id}`}
              className="mt-4 block w-full rounded-xl bg-slate-900 py-2.5 text-center text-sm font-medium text-white transition hover:bg-slate-800"
            >
              View profile and apply
            </Link>
          </div>
        </article>
      ))}
    </div>
  );
}

export default function AdoptionsPage() {
  return (
    <main className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
      <header className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">
          Adopt a rescued companion
        </h1>
        <p className="mt-2 text-base text-slate-600">
          Find verified rescued dogs and cats looking for a permanent, loving home in Sri Lanka.
        </p>
      </header>

      {/* Streaming boundary renders the page header immediately while data resolves */}
      <Suspense
        fallback={
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <AnimalCardSkeleton />
            <AnimalCardSkeleton />
            <AnimalCardSkeleton />
          </div>
        }
      >
        <AnimalGrid />
      </Suspense>
    </main>
  );
}
```

### 2. Secure Server Action with Zod validation

This scenario demonstrates validating form data on the server, verifying authentication, and calling the backend API.

```typescript
'use server';

import { revalidatePath } from 'next/cache';
import { cookies } from 'next/headers';
import { z } from 'zod';

const AdoptionApplicationSchema = z.object({
  animalId: z.string().uuid({ message: 'Invalid animal identifier format.' }),
  applicantName: z.string().min(2, { message: 'Name must be at least 2 characters long.' }).max(100),
  experienceLevel: z.enum(['Beginner', 'Intermediate', 'Experienced'], {
    message: 'Please select a valid experience level.',
  }),
  housingType: z.string().min(3, { message: 'Please describe your living arrangement.' }),
});

export type ActionState = {
  success: boolean;
  message: string;
  errors?: Record<string, string[]>;
};

export async function submitAdoptionApplicationAction(
  prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  // Read authenticated session token from secure cookie
  const cookieStore = await cookies();
  const token = cookieStore.get('hp_auth_token')?.value;

  if (!token) {
    return {
      success: false,
      message: 'You must be signed in to submit an adoption application.',
    };
  }

  // Parse raw form fields safely with Zod
  const rawData = {
    animalId: formData.get('animalId'),
    applicantName: formData.get('applicantName'),
    experienceLevel: formData.get('experienceLevel'),
    housingType: formData.get('housingType'),
  };

  const validationResult = AdoptionApplicationSchema.safeParse(rawData);

  if (!validationResult.success) {
    return {
      success: false,
      message: 'Validation failed. Please review the highlighted fields.',
      errors: validationResult.error.flatten().fieldErrors,
    };
  }

  const apiUrl = process.env.API_BASE_URL || 'http://localhost:5000';

  try {
    const response = await fetch(`${apiUrl}/api/v1/adoptions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(validationResult.data),
    });

    if (!response.ok) {
      const errorPayload = await response.json().catch(() => null);
      return {
        success: false,
        message: errorPayload?.detail || 'The adoption request could not be processed by the server.',
      };
    }

    // Refresh adoption listing cache so status updates reflect immediately
    revalidatePath('/adoptions');

    return {
      success: true,
      message: 'Your application has been submitted. A foster volunteer will review it shortly.',
    };
  } catch {
    return {
      success: false,
      message: 'Network connection to the backend service failed. Please try again.',
    };
  }
}
```

### 3. Interactive Client Component with React 19 form actions

This scenario shows a client-side form using `useActionState` and accessible inputs.

```tsx
'use client';

import { useActionState } from 'react';
import { useFormStatus } from 'react-dom';
import { submitAdoptionApplicationAction, type ActionState } from '@/actions/adoption-actions';

interface AdoptionFormProps {
  animalId: string;
  animalName: string;
}

const initialState: ActionState = {
  success: false,
  message: '',
};

function SubmitButton() {
  const { pending } = useFormStatus();

  return (
    <button
      type="submit"
      disabled={pending}
      className="w-full rounded-xl bg-blue-600 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-500 disabled:cursor-not-allowed disabled:bg-slate-300"
    >
      {pending ? 'Submitting application...' : 'Submit adoption application'}
    </button>
  );
}

export function AdoptionApplicationForm({ animalId, animalName }: AdoptionFormProps) {
  const [state, formAction] = useActionState(submitAdoptionApplicationAction, initialState);

  if (state.success) {
    return (
      <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 text-center">
        <h3 className="text-lg font-semibold text-emerald-800">Application received</h3>
        <p className="mt-2 text-sm text-emerald-700">{state.message}</p>
      </div>
    );
  }

  return (
    <form action={formAction} className="space-y-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <input type="hidden" name="animalId" value={animalId} />

      <div>
        <h2 className="text-xl font-bold text-slate-900">Apply for {animalName}</h2>
        <p className="mt-1 text-sm text-slate-500">Please provide your details for foster review.</p>
      </div>

      {state.message && !state.success && (
        <div className="rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700" role="alert">
          {state.message}
        </div>
      )}

      <div>
        <label htmlFor="applicantName" className="block text-sm font-medium text-slate-700">
          Full name
        </label>
        <input
          id="applicantName"
          name="applicantName"
          type="text"
          required
          className="mt-1.5 block w-full rounded-xl border border-slate-300 px-3.5 py-2 text-slate-900 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
        />
        {state.errors?.applicantName && (
          <p className="mt-1 text-xs text-rose-600">{state.errors.applicantName[0]}</p>
        )}
      </div>

      <div>
        <label htmlFor="experienceLevel" className="block text-sm font-medium text-slate-700">
          Pet ownership experience
        </label>
        <select
          id="experienceLevel"
          name="experienceLevel"
          required
          className="mt-1.5 block w-full rounded-xl border border-slate-300 px-3.5 py-2 text-slate-900 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
        >
          <option value="Beginner">First-time pet owner</option>
          <option value="Intermediate">Have owned pets in the past</option>
          <option value="Experienced">Experienced rescue foster or caregiver</option>
        </select>
        {state.errors?.experienceLevel && (
          <p className="mt-1 text-xs text-rose-600">{state.errors.experienceLevel[0]}</p>
        )}
      </div>

      <div>
        <label htmlFor="housingType" className="block text-sm font-medium text-slate-700">
          Housing and yard description
        </label>
        <textarea
          id="housingType"
          name="housingType"
          rows={3}
          required
          placeholder="For example: House with a secure gated garden in Kandy."
          className="mt-1.5 block w-full rounded-xl border border-slate-300 px-3.5 py-2 text-slate-900 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
        />
        {state.errors?.housingType && (
          <p className="mt-1 text-xs text-rose-600">{state.errors.housingType[0]}</p>
        )}
      </div>

      <SubmitButton />
    </form>
  );
}
```
