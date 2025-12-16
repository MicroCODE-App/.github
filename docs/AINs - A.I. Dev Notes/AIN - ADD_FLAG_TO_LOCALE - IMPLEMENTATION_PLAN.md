# Implementation Plan: Add `flag` Field to Locale Model and API

## Executive Summary

This document outlines a comprehensive plan to add `flag` field support to the `locale` entity, mirroring how `logo` exists in `club` and `org` entities. The `flag` field will store SVG content for country flags to be displayed in the UI and reporting. The seed data already contains `flag` fields, and we will update the model schema, CRUD operations, and create new API endpoints/controllers following the org/club pattern.

**Status**: Planning Phase - Validated and Ready for Approval
**Date**: 2024
**Author**: AI Assistant
**Related Files**:

- `server/model/mongo/locale.mongo.js` (ONLY file to edit - promoted to /model by setup.js)
- `server/seed/app/locale.data.js` (already has flag field)
- `server/api/locale.route.js` (NEW - to be created)
- `server/controller/locale.controller.js` (NEW - to be created)

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Requirements & Scope](#requirements--scope)
3. [Architecture Overview](#architecture-overview)
4. [Detailed Implementation Plan](#detailed-implementation-plan)
5. [API Implementation Details](#api-implementation-details)
6. [Security Considerations](#security-considerations)
7. [Testing Strategy](#testing-strategy)
8. [User Stories](#user-stories)
9. [Interface Contracts](#interface-contracts)
10. [Risk Assessment](#risk-assessment)
11. [Confidence Assessment](#confidence-assessment)

---

## Current State Analysis

### Existing Field: `flag` in Seed Data ✅

The `locale` seed data file already contains `flag` fields:

- **Location**: `server/seed/app/locale.data.js` (app-level static data)
- **Format**: SVG markup as string (e.g., `<svg xmlns="http://www.w3.org/2000/svg" ...></svg>`)
- **Coverage**: All 45 locale records have `flag` field with placeholder SVG content
- **Current State**:
  - ✅ Present in seed data
  - ❌ NOT in Mongoose schema
  - ❌ NOT handled in model CRUD operations
  - ❌ NOT available via API (no endpoints exist)

### Model Schema: Missing `flag` Field ❌

**File**: `server/model/mongo/locale.mongo.js` (ONLY file to edit)

**Important**: Files in `server/model/mongo/` are automatically promoted to `server/model/` by `server/bin/setup.js` during setup. We should ONLY edit the mongo version.

**Current Schema Fields** (lines 47-59):

- `name` (String, required)
- `country` (String, required)
- `language` (String, required)
- **Missing**: `flag` field

### CRUD Operations: Missing `flag` Handling ❌

**File**: `server/model/mongo/locale.mongo.js`

**Current `create()` Function** (lines 81-92):

- Does NOT include `flag` in `localeData` object
- Only handles: `key`, `name`, `country`, `language`
- JSDoc does NOT document `flag` parameter

**Other CRUD Functions**:

- `get()`, `getAll()`, `getByLanguage()` use `.lean()` which returns all schema fields
- `update()` uses spread operator, so it will work once schema is updated
- `delete()` - no changes needed

### API Endpoints: None Exist ❌

**Current State**: Unlike `org` and `club`, there are **no API routes or controllers** for `locale`:

- ❌ No `server/api/locale.route.js`
- ❌ No `server/controller/locale.controller.js`

**Pattern to Follow**: Based on `org` and `club`:

- Simple `list` endpoint with optional search
- Returns specific fields via `.select()`
- Uses `auth.verify('user')` middleware
- Auto-loaded via `server/api/index.js`

### Key Observations

1. **Seed data is ready**: All records have `flag` with SVG content
2. **Model needs updates**: Schema and `create()` function need `flag` support
3. **API layer needed**: Must create routes and controllers following org/club pattern
4. **File structure**: Only edit `server/model/mongo/` files (promoted by setup.js)

---

## Requirements & Scope

### Functional Requirements

1. **FR1**: Add `flag` field to Mongoose schema for `locale`
2. **FR2**: Update `create()` function to handle `flag` field
3. **FR3**: Update JSDoc for `create()` to document `flag` parameter
4. **FR4**: Create `locale.controller.js` with `list` function (following org/club pattern)
5. **FR5**: Create `locale.route.js` with GET `/api/locale` endpoint
6. **FR6**: Include `flag` in API response `.select()` clause
7. **FR7**: Support optional search by name, language, or country
8. **FR8**: Ensure `flag` field is required (must be provided)

### Non-Functional Requirements

1. **NFR1**: Maintain backward compatibility - existing fields unchanged
2. **NFR2**: Follow same pattern as `logo` field in org/club
3. **NFR3**: Follow same API pattern as org/club endpoints
4. **NFR4**: Performance - SVG strings should not significantly impact response size
5. **NFR5**: Security - SVG content should be safe (seed data is trusted)

### Out of Scope

- UI implementation (frontend changes)
- SVG validation/sanitization (seed data is trusted)
- Reporting implementation (out of scope for this phase)
- Additional API endpoints beyond `list` (can be added later if needed)

---

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                        Client UI                            │
│  (Will receive flag field in API responses)                 │
└───────────────────────┬─────────────────────────────────────┘
                        │ HTTP GET /api/locale
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    API Routes Layer                         │
│  - api/index.js (auto-loads locale.route.js)                │
│  - locale.route.js (NEW - to be created)                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  Controller Layer                           │
│  - locale.controller.js (NEW - to be created)               │
│  - list() function with search support                      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Model Layer                              │
│  - locale.mongo.js (CHANGE: add flag to schema)             │
│  - CRUD operations (CHANGE: update create())                │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  MongoDB Database                           │
│  Collection: locale                                         │
│  Fields: ..., flag (will exist after seed)                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Seed Data Layer                          │
│  - seed/app/locale.data.js                                  │
│  - Contains flag field with SVG content                     │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**API Request Flow**:

```
Client Request GET /api/locale?search=<optional>
→ api/index.js (auto-loads locale.route.js)
→ locale.route.js (auth.verify('user'))
→ locale.controller.js (validates query, builds search)
→ locale.model.js (queries MongoDB)
→ MongoDB (returns records with flag field)
→ Controller (formats response with flag)
→ Client (receives JSON with flag field)
```

**Seed Data Loading**:

```
Seed File (locale.data.js)
→ loader.js (loads data)
→ seeder.js (transforms and validates)
→ model.create() (creates records with flag field)
→ MongoDB (stores with flag field)
```

---

## Detailed Implementation Plan

### Phase 1: Model Schema Updates

#### 1.1 Update Mongoose Schema

**File**: `server/model/mongo/locale.mongo.js` (ONLY file to edit)

**Current Schema** (lines 47-59):

```javascript
// locale specific fields
name: {
    type: String,
    required: true
},
country: {
    type: String,
    required: true
},
language: {
    type: String,
    required: true
}
```

**Change To**:

```javascript
// locale specific fields
name: {
    type: String,
    required: true
},
country: {
    type: String,
    required: true
},
language: {
    type: String,
    required: true
},
flag: {
    type: String,
    required: true
}
```

**Impact**: Low risk, additive change only

**Note**: This file is automatically promoted to `server/model/locale.model.js` by `server/bin/setup.js`, so we only edit the mongo version.

### Phase 2: CRUD Operations Updates

#### 2.1 Update `create()` Function

**File**: `server/model/mongo/locale.mongo.js`

**Current Code** (lines 81-92):

```javascript
exports.create = async function ({ key = "", name, country, language }) {
  const localeData = {
    key: key,
    name: name,
    country: country,
    language: language,
  };

  // Instantiate through Mongoose to ensure schema field order
  return await mongo.createOrdered(KEY_PREFIX, Locale, localeData);
};
```

**Change To**:

```javascript
exports.create = async function ({ key = "", name, country, language, flag }) {
  const localeData = {
    key: key,
    name: name,
    country: country,
    language: language,
    flag: flag,
  };

  // Instantiate through Mongoose to ensure schema field order
  return await mongo.createOrdered(KEY_PREFIX, Locale, localeData);
};
```

**Also Update JSDoc** (lines 69-79):

```javascript
/**
 * @func create
 * @memberof model.mongo.locale
 * @desc [C]RUD Create a new locale record.
 * @api public
 * @param {object} params Parameters object
 * @param {string} [params.key] Unique locale key (e.g., 'en-US', 'es-ES')
 * @param {string} params.name Locale display name (e.g., 'English (United States)')
 * @param {string} params.country Country code (e.g., 'US', 'ES')
 * @param {string} params.language Language code (e.g., 'en', 'es')
 * @param {string} params.flag Flag SVG markup string
 * @returns {Promise<object>} Created locale object
 */
```

**Impact**: Low risk, additive change only

#### 2.2 Other CRUD Functions

**No Changes Needed**:

- `get()` - Uses `.lean()`, will automatically return `flag` once schema updated
- `getAll()` - Uses `.lean()`, will automatically return `flag` once schema updated
- `getByLanguage()` - Uses `.lean()`, will automatically return `flag` once schema updated
- `update()` - Uses spread operator `...data`, will handle `flag` automatically
- `delete()` - No changes needed

### Phase 3: Controller Creation

#### 3.1 Create Locale Controller

**File**: `server/controller/locale.controller.js` (NEW FILE)

**Pattern**: Follow `org.controller.js` and `club.controller.js` pattern

**Implementation**:

```javascript
const joi = require("joi");
const locale = require("../model/locale.model");
const utility = require("../helper/utility");

/* CRUD
 * locale.* - Create, Read, Update, Delete functions
 */

/**
 * @func list
 * @memberof controller.locale
 * @desc C[R]UD List locales with optional search by name, language, or country.
 * @api private
 * @param {object} req - Express request object (requires authentication middleware)
 * @param {object} req.query - Query parameters
 * @param {string} [req.query.search] - Search term to filter by name, language, or country
 * @param {object} res - Express response object
 * @returns {Promise<void>} Sends array of locale objects
 */
exports.list = async function (req, res) {
  const schema = joi.object({
    search: joi.string().allow(""),
  });

  const { error, value } = schema.validate(req.query, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).send({
      message: error.details.map((err) => err.message).join(", "),
    });
  }

  const search = value?.search || "";

  // Build search query
  const query = {};
  if (search) {
    query.$or = [
      { name: { $regex: search, $options: "i" } },
      { language: { $regex: search, $options: "i" } },
      { country: { $regex: search, $options: "i" } },
    ];
  }

  const locales = await locale.schema
    .find(query)
    .select("id key name country language flag")
    .lean()
    .sort({ name: 1 });

  res.status(200).send({
    data: locales,
  });
};
```

**Key Features**:

- Follows org/club controller pattern exactly
- Search by name, language, or country (using `$or`)
- Returns: `id`, `key`, `name`, `country`, `language`, `flag`
- Sorted by name ascending
- Uses JSDoc format matching org/club

**Impact**: Low risk, follows established pattern

### Phase 4: API Route Creation

#### 4.1 Create Locale Route

**File**: `server/api/locale.route.js` (NEW FILE)

**Pattern**: Follow `org.route.js` and `club.route.js` pattern

**Implementation**:

```javascript
const express = require("express");
const auth = require("../model/auth.service");
const localeController = require("../controller/locale.controller");
const api = express.Router();
const use = require("../helper/utility").use;

api.get("/api/locale", auth.verify("user"), use(localeController.list));

module.exports = api;
```

**Key Features**:

- Follows org/club route pattern exactly
- Uses `auth.verify('user')` middleware
- Uses `use()` HOF for error handling
- Auto-loaded by `server/api/index.js`

**Impact**: Low risk, follows established pattern

---

## API Implementation Details

### API Endpoint Specification

#### GET /api/locale

**Request**:

```
GET /api/locale?search=<optional>
Headers: Authorization: Bearer <token>
```

**Query Parameters**:

- `search` (optional): Search term to filter by name, language, or country (case-insensitive)

**Response Format**:

```json
{
  "data": [
    {
      "id": "locl_...",
      "key": "en-US",
      "name": "English (United States)",
      "country": "US",
      "language": "en",
      "flag": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"64\" height=\"64\" viewBox=\"0 0 24 24\" fill=\"none\"></svg>"
    }
  ]
}
```

**Fields Returned**:

- `id`: Locale ID
- `key`: Locale key (e.g., 'en-US')
- `name`: Display name
- `country`: Country code
- `language`: Language code
- `flag`: SVG markup string (required)

**Search Behavior**:

- Searches across `name`, `language`, and `country` fields
- Case-insensitive regex match
- Returns all matching locales sorted by name

**Authentication**: Requires `user` permission level

**Error Responses**:

- `400`: Invalid query parameters
- `401`: Unauthorized (missing/invalid token)
- `500`: Server error

### Backward Compatibility

✅ **Fully Backward Compatible**:

- New API endpoint (doesn't affect existing code)
- New field is optional
- Existing model methods continue to work
- No breaking changes

---

## Security Considerations

### SVG Content Security

**Current State**: Seed data contains SVG strings (trusted source)

**Risk Assessment**: **Low Risk**

- Seed data is controlled and trusted
- No user input involved
- SVG content is static
- API endpoint requires authentication

**Recommendation**:

- No sanitization needed for seed data
- If user input is added later, implement sanitization at that time

### API Security

- Endpoint requires `auth.verify('user')` middleware
- Follows same security pattern as org/club endpoints
- Input validation via Joi schema
- No SQL injection risk (MongoDB)

---

## Testing Strategy

### Unit Tests

1. **Model Tests**:

   - Test `create()` with `flag` field
   - Test `create()` without `flag` field (backward compatibility)
   - Test `update()` with `flag` field
   - Test schema validation

2. **Controller Tests**:

   - Test list endpoint returns `flag` field
   - Test list endpoint with search (ensures field included)
   - Test `flag` field is always present (required validation)
   - Test search by name, language, country

3. **Route Tests**:
   - Test authentication required
   - Test route registration
   - Test error handling

### Integration Tests

1. **API Integration**:

   - Test GET /api/locale returns `flag` field
   - Test GET /api/locale with search parameter
   - Test authentication still works
   - Test search functionality works
   - Test `flag` field validation (must be provided)

2. **Database Integration**:
   - Test records created with `flag` persist correctly
   - Test queries return `flag` field via `.lean()`
   - Test `getAll()`, `get()`, `getByLanguage()` include `flag`

### Manual Testing Checklist

- [ ] Seed data loads without errors
- [ ] Model `create()` accepts `flag` parameter
- [ ] API endpoint `/api/locale` exists and is accessible
- [ ] API endpoint returns `flag` field
- [ ] Search functionality works (name, language, country)
- [ ] Authentication required (401 without token)
- [ ] Records without `flag` return null/undefined (not error)
- [ ] Response sorted by name
- [ ] No performance degradation

---

## User Stories

### US1: Display Locale Flag in UI

**As a** frontend developer
**I want to** receive the `flag` field when calling `/api/locale`
**So that** I can display country flags in the UI

**Acceptance Criteria**:

- GET /api/locale returns `flag` field
- Flag contains valid SVG markup
- Flag displays correctly in UI (out of scope for this implementation)

### US2: Search Locales

**As a** user
**I want to** search locales by name, language, or country
**So that** I can quickly find the locale I need

**Acceptance Criteria**:

- Search parameter works across name, language, and country
- Search is case-insensitive
- Results include `flag` field

### US3: Display Locale Flag in Reporting

**As a** developer generating reports
**I want to** access the `flag` field from locale API
**So that** I can include country flags in reports

**Acceptance Criteria**:

- API returns `flag` field
- Flag can be included in report generation
- Flag displays correctly in reports (out of scope for this implementation)

### US4: Backward Compatibility

**As a** developer using the locale model
**I want** existing code to continue working
**So that** I don't need to update my code immediately

**Acceptance Criteria**:

- All existing fields still present
- New field is required (must be provided in all records)
- Existing model method calls still work

---

## Interface Contracts

### Model Interface

#### `locale.mongo.js`

**Schema Field**:

```typescript
flag: string; // Required SVG markup string
```

**Create Function**:

```typescript
create(params: {
    key?: string;
    name: string;
    country: string;
    language: string;
    flag: string;  // NEW - required
}): Promise<Locale>
```

### API Interface

#### GET /api/locale

**Request**:

```
GET /api/locale?search=<optional>
Headers: Authorization: Bearer <token>
```

**Response**:

```typescript
{
  data: Array<{
    id: string;
    key: string;
    name: string;
    country: string;
    language: string;
    flag: string; // NEW - required SVG string
  }>;
}
```

---

## Risk Assessment

### Low Risk ✅

1. **Schema Changes**: Adding required field is low risk (all seed data has flag)
2. **CRUD Updates**: Additive changes only
3. **API Creation**: Follows established pattern exactly
4. **Backward Compatibility**: Existing code will continue to work
5. **Seed Data**: Already contains `flag`, just needs model support

### Medium Risk ⚠️

1. **New Files**: Creating controller and route files (low risk, follows pattern)
2. **Route Registration**: Auto-loaded by index.js (should work automatically)

### High Risk ❌

1. **None identified** - This follows established patterns

### Mitigation Strategies

- **New Files**: Follow exact pattern from org/club files
- **Route Registration**: Verify auto-loading works (index.js handles it)
- **Testing**: Comprehensive testing before deployment

---

## Confidence Assessment

### Current Confidence Level: **98%**

### High Confidence Areas ✅

1. **Schema Changes**: 100% confident

   - Simple field addition
   - Follows same pattern as `logo` in org/club
   - Only one file to edit (mongo version)

2. **CRUD Updates**: 100% confident

   - Additive changes only
   - `create()` update is straightforward
   - Other functions work automatically

3. **Controller Creation**: 100% confident

   - Follows org/club pattern exactly
   - Search logic is clear
   - Field selection is explicit

4. **Route Creation**: 100% confident

   - Follows org/club pattern exactly
   - Auto-loaded by index.js
   - Simple GET endpoint

5. **Seed Data**: 100% confident

   - Already contains `flag` field
   - All records consistent
   - No changes needed

6. **Backward Compatibility**: 100% confident
   - Additive change only
   - No breaking changes
   - Existing fields unchanged

### Remaining Uncertainties (2%)

1. **Search Fields**: 1% uncertainty

   - **Question**: Should search include `key` field as well?
   - **Answer**: Following org/club pattern, they search by `acronym` and `name`. For locale, searching by `name`, `language`, and `country` makes sense. `key` could be added if needed.
   - **Mitigation**: Can add `key` to search if requested

2. **Field Selection**: 1% uncertainty
   - **Question**: Should we return all fields or specific ones?
   - **Answer**: Following org/club pattern, we return specific fields via `.select()`. For locale: `id`, `key`, `name`, `country`, `language`, `flag` seems appropriate.
   - **Mitigation**: Can adjust field selection if needed

### Questions to Reach 100% Confidence

**None required** - The 2% uncertainty is acceptable and can be adjusted during implementation if needed. The implementation follows established patterns exactly.

---

## Implementation Checklist

### Pre-Implementation

- [x] Review and validate plan
- [x] Answer clarifying questions
- [x] Verify file structure (mongo promotion)
- [x] Understand org/club patterns
- [ ] Set up test environment (if needed)
- [ ] Backup database (if applicable)

### Implementation Steps

- [ ] Update `locale.mongo.js` schema (add `flag` field)
- [ ] Update `locale.mongo.js` `create()` function (add `flag` parameter)
- [ ] Update JSDoc for `create()` in `locale.mongo.js`
- [ ] Create `locale.controller.js` with `list` function
- [ ] Create `locale.route.js` with GET endpoint
- [ ] Test seed data loading
- [ ] Test model CRUD operations
- [ ] Test API endpoint
- [ ] Verify route auto-loading
- [ ] Test search functionality

### Post-Implementation

- [ ] Run seed process
- [ ] Verify API endpoint returns `flag` field
- [ ] Test backward compatibility
- [ ] Performance testing (response times)
- [ ] ESLint both new files
- [ ] Update documentation (if needed)

---

## Conclusion

This implementation plan outlines adding `flag` field support to the `locale` entity and creating API endpoints, following the exact same pattern as `logo` in `org` and `club`. The work involves:

1. **Model Layer**: Add field to schema and update `create()` function (1 file)
2. **Controller Layer**: Create new controller with `list` function (1 new file)
3. **API Layer**: Create new route file (1 new file)
4. **Seed Data**: Already complete (no changes needed)

**Estimated Complexity**: Low
**Estimated Time**: 2-3 hours
**Risk Level**: Very Low
**Confidence Level**: 98%

**Key Points**:

- ✅ Seed data already has `flag` field
- ✅ Model updates are straightforward
- ✅ API follows established org/club pattern
- ✅ Only edit `server/model/mongo/` files (promoted by setup.js)
- ✅ Fully backward compatible
- ✅ No breaking changes

**Next Steps**:

1. Review this validated plan
2. Approve implementation
3. Proceed with code changes

---

## Appendix

### File Change Summary

| File                                     | Changes                                 | Lines Affected       | Risk |
| ---------------------------------------- | --------------------------------------- | -------------------- | ---- |
| `server/model/mongo/locale.mongo.js`     | Add `flag` to schema, update `create()` | ~8 lines             | Low  |
| `server/controller/locale.controller.js` | Create new controller file              | ~60 lines (new file) | Low  |
| `server/api/locale.route.js`             | Create new route file                   | ~10 lines (new file) | Low  |

**Total Estimated Changes**:

- **Model**: ~8 lines modified
- **Controller**: ~60 lines (new file)
- **Route**: ~10 lines (new file)

### Code Diff Preview

**locale.mongo.js Schema**:

```diff
    language: {
        type: String,
        required: true
    }
+   flag: {
+       type: String,
+       required: false
+   }
});
```

**locale.mongo.js create()**:

```diff
- exports.create = async function({ key = '', name, country, language })
+ exports.create = async function({ key = '', name, country, language, flag })
  {
      const localeData = {
          key: key,
          name: name,
          country: country,
-         language: language
+         language: language,
+         flag: flag
      };
```

**locale.controller.js** (new file):

```javascript
const joi = require("joi");
const locale = require("../model/locale.model");
const utility = require("../helper/utility");

/* CRUD
 * locale.* - Create, Read, Update, Delete functions
 */

/**
 * @func list
 * @memberof controller.locale
 * @desc C[R]UD List locales with optional search by name, language, or country.
 * @api private
 * @param {object} req - Express request object (requires authentication middleware)
 * @param {object} req.query - Query parameters
 * @param {string} [req.query.search] - Search term to filter by name, language, or country
 * @param {object} res - Express response object
 * @returns {Promise<void>} Sends array of locale objects
 */
exports.list = async function (req, res) {
  const schema = joi.object({
    search: joi.string().allow(""),
  });

  const { error, value } = schema.validate(req.query, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).send({
      message: error.details.map((err) => err.message).join(", "),
    });
  }

  const search = value?.search || "";

  // Build search query
  const query = {};
  if (search) {
    query.$or = [
      { name: { $regex: search, $options: "i" } },
      { language: { $regex: search, $options: "i" } },
      { country: { $regex: search, $options: "i" } },
    ];
  }

  const locales = await locale.schema
    .find(query)
    .select("id key name country language flag")
    .lean()
    .sort({ name: 1 });

  res.status(200).send({
    data: locales,
  });
};
```

**locale.route.js** (new file):

```javascript
const express = require("express");
const auth = require("../model/auth.service");
const localeController = require("../controller/locale.controller");
const api = express.Router();
const use = require("../helper/utility").use;

api.get("/api/locale", auth.verify("user"), use(localeController.list));

module.exports = api;
```

---

_End of Implementation Plan_
