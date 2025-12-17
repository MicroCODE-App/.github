# MicroCODE App Template - Project Instructions

## Overview

**MicroCODE App Template** is an enterprise SaaS application platform built on the Gravity SaaS Boilerplate. This is a **monorepo template** where all changes flow downstream into production web applications.

**⚠️ IMPORTANT**: This is a template repository. All modifications should be made with downstream applications in mind.

## Architecture

### Five-Component Solution

The platform consists of six (6) integrated components:

- **Server**: Node.js backend API and business logic
- **Client**: React web frontend application
- **App**: React Native mobile applications (iOS & Android)
- **Admin**: A private Node.js backend API server for the Admin Console
- **Admin/Console**: Node.js server and React-based admin console for backend management
- **Portal**: Astro-based marketing website
- **Database**: MongoDB (with SQL support via Knex.js)

#### 1. Server (`server/`)

- **Technology**: Node.js, Express, MongoDB (with SQL support via Knex.js)
- **Purpose**: Backend API, business logic, database operations
- **Key Features**:
  - RESTful API with Swagger documentation
  - Entity-centric architecture with `__config.js` as single source of truth
  - Multi-tenant with `account_id` scoping
  - Authentication via Passport.js
  - Stripe integration for billing
  - Redis caching
  - Background workers (Bull.js)
- **Structure**:
  - `api/` - API routes (grouped by entity)
  - `controller/` - Business logic layer
  - `model/` - Database interaction layer
  - `helper/` - Reusable utilities
  - `migrations/` - Database migrations
  - `locales/` - i18n translation files
  - `worker/` - Background job processors
- **Special Construction**:
  - `model/` - this is populated with files from /model/mongo or /model/sql depending on build
  - So, all edits to models needs to occur in /mongo and /sql files, unless the file is ONLY found in the /model root.

#### 2. Client (`client/`)

- **Technology**: React, React Router, Shadcn UI, Tailwind CSS, Vite
- **Purpose**: Web frontend application
- **Key Features**:
  - React Router for navigation
  - Shadcn UI component library
  - Tailwind CSS for styling
  - i18next for internationalization
  - Stripe Elements integration
  - Private route protection
- **Structure**:
  - `src/app/` - Router and authentication
  - `src/components/` - Reusable UI components
  - `src/views/` - Page components
  - `src/routes/` - Route definitions
  - `src/utils/` - Utility functions
  - `src/locales/` - Translation files

#### 3. App (`app/`)

- **Technology**: React Native, Expo
- **Purpose**: Mobile applications (iOS & Android)
- **Key Features**:
  - Cross-platform mobile app
  - Shared authentication with web
  - Native device features
- **Structure**:
  - `components/` - React Native components
  - `views/` - Screen components
  - `locales/` - Translation files

#### 4. Admin (`admin/`)

- **Technology**: React-based admin console
- **Purpose**: Backend control and maintenance interface
- **Key Features**:
  - User and account management
  - System monitoring
  - Administrative tools

#### 5. Portal (`portal/`)

- **Technology**: Astro
- **Purpose**: Marketing website
- **Key Features**:
  - Static site generation
  - Marketing pages
  - Documentation

## Entity-Centric Architecture

The server uses an **entity-centric** architecture where `__config.js` serves as the single source of truth. This configuration automatically generates:

- Database schemas
- API endpoints (GET, POST, PUT, DELETE)
- Swagger documentation
- Authorization middleware
- UI views and forms

### File Naming Convention

- `/api/{entity}.route.js` - API routes
- `/model/{entity}.model.js` - Models
- `/controller/{entity}.controller.js` - Controllers
- `/locales/{entity}.{locale}.json` - Locale files

## Database Architecture

- **Primary**: MongoDB (with SQL support via Knex.js)
- **Scoping**: All queries use `account_id` for multi-tenant security
- **Relationships**:
  - `account` - Main organization entity
  - `account_users` - User-account relationships with permissions
  - All tables secured by `account_id` foreign keys

## Authentication & Authorization

- **Authentication**: Passport.js with 500+ social providers, email/password, magic links, 2FA
- **Authorization**: Permission-based system with roles (owner, admin, user)
- **API Protection**: `auth.verify()` middleware with permission and scope requirements

## Development Workflow

### Issue Tracking

- **Centralized**: All issues in `MicroCODE-App-Template/.issue` repository
- **Branch Naming**: `feature/0123--short-name` (zero-padded 4-digit issue numbers)
- **PR References**: `Refs MicroCODE-App-Template/.issue#1234`

### Code Quality

- **ESLint**: Component-specific configs in each repo
- **Style Guide**: https://github.com/MicroCODEIncorporated/JavaScriptSG.git
- **Documentation**: JSDoc headers for all exported functions

### AI Development Notes

- **Location**: `.github/docs/AINs/`
- **Template**: `AIN - WORKFLOW_TEMPLATE.md`
- **Naming**: Follow existing pattern in directory

## Key Technologies

- **Backend**: Node.js 22+, Express, MongoDB, Redis
- **Frontend**: React 18+, React Router, Shadcn UI, Tailwind CSS
- **Mobile**: React Native, Expo
- **Payments**: Stripe
- **Email**: Mailgun
- **Testing**: Mocha, Chai
- **Documentation**: Swagger, JSDoc

## Security Considerations

- All database queries must include `account_id` constraint
- Input validation in controllers using Joi schemas
- Parameterized queries (no raw SQL unless necessary)
- Prevent mass assignment by destructuring only expected fields
- API throttling and rate limiting

## Common Patterns

### API Route Pattern

```javascript
api.get(
  "/api/{entity}",
  auth.verify("permission", "api.scope", "unverified"),
  use(controller.get)
);
```

### Controller Pattern

```javascript
const data = utility.validate(
  joi.object({
    field: joi.string().required(),
  }),
  req,
  res
);
```

### Model Pattern

```javascript
const db = require("./knex")();
await db("table").where({ account_id }).insert({ ... });
```

## Getting Started

1. Review `.github/docs/DEV/DEVELOPER-SETUP.md` for environment setup
2. Check component-specific rules in `.cursor/rules/`
3. Follow the AI workflow template when starting new tasks
4. Reference `AI-RULES.md` for coding standards

## Important Files

- `.github/docs/AI/AI-RULES.md` - Complete coding standards
- `.github/docs/DEV/DEVELOPER-SETUP.md` - Setup instructions
- `.cursor/rules/*.mdc` - Component-specific rules
- `server/__config.js` - Entity configuration (if exists)
