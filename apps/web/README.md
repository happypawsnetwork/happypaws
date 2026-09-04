<a href="https://github.com/happypaws-lk/happypaws" align="center">
    <img src=".github/assets/banner.jpg" alt="HappyPaws Web Platform">
</a>

<p align="center">The official web application for HappyPaws.lk.</p>

<!-- Badges -->
<p align="center">
  <img src="https://img.shields.io/badge/Next.js-16.0-000000?style=flat&logo=next.js&labelColor=171717" alt="Next.js" />
  <img src="https://img.shields.io/badge/React-19.0-61dafb?style=flat&logo=react&labelColor=171717" alt="React" />
  <img src="https://img.shields.io/badge/TypeScript-5.0-3178C6?style=flat&logo=typescript&labelColor=171717" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Tailwind_CSS-4.0-06B6D4?style=flat&logo=tailwind-css&labelColor=171717" alt="Tailwind CSS" />
  <img src="https://img.shields.io/badge/License-Proprietary-c03dfe?style=flat&labelColor=171717" alt="License" />
</p>

<h4 align="center">
    <a href="#introduction">Introduction</a> 
    <span> · </span>    
    <a href="#getting-started">Getting started</a>
    <span> · </span>
    <a href="#tech-stack">Tech stack</a>
</h4>

<br />

## Introduction

HappyPaws.lk is a verified identity and reputation led platform for animal rescue, adoption, and rehoming in Sri Lanka. This directory contains the **Web Application**, which serves as the primary user portal for browsing adoptable pets, submitting adoption applications, offering temporary foster homes, coordinating animal transport, and supporting emergency rescues.

## Tech stack

- [Next.js](https://nextjs.org/) (v16 App Router)
- [React](https://react.dev/) (v19)
- [TypeScript](https://www.typescriptlang.org/) (v5+)
- [Tailwind CSS](https://tailwindcss.com/) (v4)
- [Framer Motion](https://www.framer.com/motion/)

## Getting started

1. **Install dependencies**
   From the repository root, install dependencies for all workspace projects using pnpm:

   ```bash
   pnpm install
   ```

2. **Configure environment variables**
   Create a local environment file before running the web app:

   ```bash
   cp .env.example .env.local
   ```

   This configures the `NEXT_PUBLIC_API_URL`, allowing the frontend to communicate with your local API.

3. **Start development server**
   From the repository root, start the web app using Turborepo:
   ```bash
   pnpm run dev:web
   ```
   Alternatively, run it directly from this directory:
   ```bash
   pnpm run dev
   ```
   Open `http://localhost:3000` in your browser to view the application.

## Contact

Reach out to the development team if you have any questions.
