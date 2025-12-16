# Implementation Plan: Expand Edit Your Profile Dialog

## Table of Contents

1. [Overview](#overview)
2. [Architecture Diagrams](#architecture-diagrams)
3. [Interface Contracts](#interface-contracts)
4. [User Stories](#user-stories)
5. [File-by-File Implementation Details](#file-by-file-implementation-details)
6. [Data Flow Diagrams](#data-flow-diagrams)
7. [Security Considerations](#security-considerations)
8. [Questions for Clarification](#questions-for-clarification)

---

## Overview

This implementation plan details the step-by-step process for expanding the "Edit Your Profile" dialog with accordion fields and adding Organizations/Clubs/SVs management pages.

### Key Changes Summary

1. **Profile Page Refactor**: Convert text inputs to full-width read-only display fields with accordion behavior
2. **New Component**: Create `ProfileCollapsibleField` component for label-above, full-width display fields
3. **Organizations Page**: New page for managing `org_ids` with "+" dropdown
4. **Clubs Page**: New page for managing `club_ids` with "+" dropdown
5. **SVs Page**: New page for managing `sv_ids` with "+" dropdown (creates SV from BOAT selection)
6. **Backend Updates**: Add validation for `org_ids`, `club_ids`, `sv_ids` arrays

---

## Architecture Diagrams

### Component Hierarchy

```
Profile Page (profile.jsx)
├── Animate
│   └── Row
│       └── Card
│           ├── User Info Section
│           │   ├── ProfileCollapsibleField (name)
│           │   │   ├── Label (above)
│           │   │   ├── Display Field (full width, read-only)
│           │   │   └── CollapsibleContent
│           │   │       └── Detail Fields (horizontal layout)
│           │   ├── ProfileCollapsibleField (email)
│           │   ├── ProfileCollapsibleField (phone)
│           │   ├── ProfileCollapsibleField (address) [required]
│           │   └── SettingRow (avatar - file input)
│           └── Account Info Section
│               ├── SettingRow (account_name - owner only)
│               └── SettingRow (default_account_id - multi-account only)
│
Organizations Page (organizations.jsx)
├── Animate
│   └── Row
│       └── Card
│           ├── Help Card
│           └── Form (settingsMode=true)
│               ├── Organizations List (SettingRow for each)
│               └── Add Button (+ dropdown)
│
Clubs Page (clubs.jsx) [Same structure as Organizations]
SVs Page (svs.jsx) [Same structure as Organizations]
```

### Data Flow

```
User Action → React Component → API Call → Controller → Model → Database
                ↓                    ↓           ↓         ↓
            State Update      Validation   Business   Persistence
                                            Logic
```

### Entity Relationships

```
USER
├── org_ids: [org_id1, org_id2, ...]
├── club_ids: [club_id1, club_id2, ...]
└── sv_ids: [sv_id1, sv_id2, ...]

ORG ──┐
      ├── Referenced by USER.org_ids
CLUB ─┤
      └── Referenced by USER.club_ids

BOAT ──┐
       ├── Referenced by SV.boat_id
       └── Multiple SVs can reference same BOAT

SV
├── boat_id: → BOAT
├── user_ids: { owner_id: USER.id, ... }
└── certs: { ... }
    └── Referenced by USER.sv_ids
```

---

## Interface Contracts

### 1. ProfileCollapsibleField Component

**File**: `client/src/components/form/profile-collapsible-field/profile-collapsible-field.jsx` (CREATE)

**Props Interface**:

```typescript
interface ProfileCollapsibleFieldProps {
  control: Control; // react-hook-form control
  displayField: {
    name: string; // Field name (e.g., 'name', 'email')
    labelKey: string; // Translation key for label
    required?: boolean; // Is field required?
    placeholder?: string; // Placeholder text
  };
  detailFields: Array<{
    name: string; // Dot notation field name (e.g., 'name_.first')
    labelKey: string; // Translation key for label
    type: "text" | "email" | "select"; // Field type
    options?: Array<{ value: string; label: string }>; // For select fields
    rules?: object; // Validation rules
    placeholder?: string;
  }>;
  open: boolean; // Controlled open state
  onOpenChange: (isOpen: boolean) => void; // Callback for open state change
  watch: UseFormWatch; // react-hook-form watch function
  setValue: UseFormSetValue; // react-hook-form setValue function
  errors: FieldErrors; // react-hook-form errors
  t: (key: string) => string; // Translation function
}
```

**Behavior**:

- Label appears above display field
- Display field is full width
- Clicking display field or chevron expands accordion
- Detail fields use horizontal layout (label left, input right)
- Real-time updates to display field as user edits details

### 2. Organizations/Clubs/SVs Page Component

**File**: `client/src/views/account/organizations.jsx` (CREATE)

**Props Interface**:

```typescript
interface OrganizationsPageProps {
  t: (key: string) => string; // Translation function
}
```

**State Interface**:

```typescript
interface OrganizationsPageState {
  user: {
    org_ids: string[]; // Current user's organization IDs
    loading: boolean;
    data?: User;
  };
  availableOrgs: {
    data: Org[]; // Available organizations from API
    loading: boolean;
  };
  selectedOrgIds: string[]; // Form state for selected orgs
}
```

**API Contracts**:

**GET /api/user**

```typescript
Response: {
  data: {
    id: string;
    org_ids: string[];
    club_ids: string[];
    sv_ids: string[];
    // ... other user fields
  }
}
```

**GET /api/org** (or equivalent)

```typescript
Response: {
  data: Array<{
    id: string;
    name: string;
    description?: string;
    // ... other org fields
  }>;
}
```

**PATCH /api/user**

```typescript
Request: {
  org_ids: string[];                    // Array of organization IDs
  // ... other user fields
}

Response: {
  data: {
    id: string;
    org_ids: string[];
    // ... updated user fields
  }
}
```

### 3. Backend Controller Interface

**File**: `server/controller/user.controller.js` (MODIFY)

**Update Function Validation Schema**:

```javascript
joi.object({
  // ... existing fields ...
  org_ids: joi.array().items(joi.string()).optional(),
  club_ids: joi.array().items(joi.string()).optional(),
  sv_ids: joi.array().items(joi.string()).optional(),
  // ... other fields ...
});
```

**Update Function Behavior**:

- Accepts `org_ids`, `club_ids`, `sv_ids` as arrays of strings
- Validates that IDs exist in respective collections (org, club, sv)
- Updates user document with new arrays
- Returns updated user data

---

## User Stories

### Story 1: Edit Profile with Accordion Fields

**As a** user
**I want to** edit my profile information using accordion-style fields
**So that** I can see a clean summary view and expand to edit details when needed

**Acceptance Criteria**:

- [ ] Name, email, phone, address fields display as read-only summary fields
- [ ] Labels appear above display fields (not to the left)
- [ ] Display fields are full width
- [ ] Clicking a display field expands accordion showing detail fields
- [ ] Detail fields use horizontal layout (label left, input right)
- [ ] Display fields update in real-time as I edit details
- [ ] Clicking email/phone opens accordion (does NOT trigger mailto/tel)
- [ ] Address field is required with error message
- [ ] Form saves all changes on Submit

### Story 2: Manage Organizations

**As a** user
**I want to** manage the organizations I belong to
**So that** I can connect with other members and show my affiliations

**Acceptance Criteria**:

- [ ] Page displays list of organizations I belong to
- [ ] "+" button shows dropdown of available organizations
- [ ] Selecting organization from dropdown adds it to my list
- [ ] Each organization in list has remove button
- [ ] Changes save on form submit
- [ ] Help card explains what organizations are

### Story 3: Manage Clubs

**As a** user
**I want to** manage the clubs I belong to
**So that** I can connect with sailing/boating community members

**Acceptance Criteria**:

- [ ] Same as Story 2, but for clubs
- [ ] "+" button shows dropdown of available clubs
- [ ] Help card explains what clubs are

### Story 4: Manage SVs (Boats)

**As a** user
**I want to** claim ownership of boats
**So that** I can track my sailing vessels and their details

**Acceptance Criteria**:

- [ ] Page displays list of SVs I own
- [ ] "+" button shows dropdown of available BOATs
- [ ] Selecting a BOAT creates an SV linking me (USER) + BOAT
- [ ] SV is added to my `sv_ids` array
- [ ] Each SV in list shows boat name
- [ ] Each SV has remove button
- [ ] Help card explains BOAT vs SV relationship
- [ ] Note: CERT management is future enhancement

### Story 5: Navigate to New Pages

**As a** user
**I want to** easily navigate to Organizations/Clubs/SVs pages
**So that** I can manage my affiliations

**Acceptance Criteria**:

- [ ] Account index page shows cards for Organizations, Clubs, SVs
- [ ] Account subnav includes menu items for all three pages
- [ ] Clicking cards or menu items navigates to respective pages

---

## File-by-File Implementation Details

### Frontend Files

#### 1. ProfileCollapsibleField Component (NEW)

**File**: `client/src/components/form/profile-collapsible-field/profile-collapsible-field.jsx`

**Purpose**: Custom collapsible field component for Profile page with label-above, full-width display

**Key Differences from CollapsibleSettingRow**:

- Label appears **above** display field (not to the left)
- Display field is **full width** (not 70% control width)
- Detail fields use **horizontal layout** (same as CollapsibleSettingRow)

**Implementation Steps**:

1. Create component file and directory
2. Import dependencies: `Collapsible`, `CollapsibleTrigger`, `CollapsibleContent`, `SettingRow`, `Input`, `Select`, `Controller`
3. Implement display field rendering (label above, full width)
4. Implement accordion behavior (controlled open state)
5. Implement detail fields rendering (horizontal layout)
6. Implement real-time display field updates (useEffect watching detail fields)
7. Handle email/phone click behavior (open accordion, not mailto/tel)
8. Export component

**Dependencies**:

- `@radix-ui/react-collapsible` (already exists)
- `react-hook-form` (already exists)
- Existing form components

#### 2. Profile Page (MODIFY)

**File**: `client/src/views/account/profile.jsx`

**Current State**: Uses simple `Form` component with `inputs` object

**Changes Required**:

1. Replace `Form` component with custom form using `react-hook-form`
2. Import `ProfileCollapsibleField` component
3. Import utility functions: `parseName`, `parseAddress`, `formatPhone`
4. Implement `useForm` hook with default values
5. Parse `name_`, `email_`, `phone_`, `address_` from user data (same logic as UserEditForm)
6. Add User Info Section with `ProfileCollapsibleField` components
7. Add Account Info Section with regular `SettingRow` components
8. Implement form submission handler (PATCH `/api/user`)
9. Update `authContext` on successful save
10. Add visual separator between sections

**Key Implementation Details**:

- Use `ProfileCollapsibleField` for name, email, phone, address
- Address field must be required (add validation)
- Email/phone click handlers open accordion (not mailto/tel)
- Keep avatar, account_name, default_account_id as regular fields
- Use `settingsMode={false}` or custom layout (not iOS-style for display fields)

#### 3. Organizations Page (CREATE)

**File**: `client/src/views/account/organizations.jsx`

**Pattern**: Follow `notifications.jsx` structure

**Implementation Steps**:

1. Create file with basic structure (Animate, Row, Card)
2. Add help card component
3. Use `useAPI` hook to fetch user data (`/api/user`)
4. Use `useAPI` hook to fetch available organizations (`/api/org` or equivalent)
5. Implement state for selected organization IDs
6. Render list of user's organizations (from `user.org_ids`)
7. Implement "+" button with dropdown/popover
8. Populate dropdown with available organizations (filter out already selected)
9. Handle add organization (add to selectedOrgIds state)
10. Handle remove organization (remove from selectedOrgIds state)
11. Implement form submission (PATCH `/api/user` with updated `org_ids`)
12. Show success/error notifications

**UI Components**:

- Help card (info box)
- List of organizations (SettingRow for each, or custom list)
- "+" button with dropdown (use Popover or Select component)
- Remove button for each organization

#### 4. Clubs Page (CREATE)

**File**: `client/src/views/account/clubs.jsx`

**Implementation**: Same as Organizations, but:

- Fetch from `/api/club` (or equivalent)
- Update `club_ids` array
- Use club-specific locales

#### 5. SVs Page (CREATE)

**File**: `client/src/views/account/svs.jsx`

**Implementation**: Similar to Organizations, but:

- Fetch BOATs from `/api/boat` (or equivalent)
- When user selects BOAT, create SV entity:
  - Call POST `/api/sv` (or equivalent) with `boat_id` and `user_ids: { owner: current_user_id }`
  - Add created SV's ID to `user.sv_ids`
- Display SV list showing boat name (from SV.boat_id → BOAT.name)
- Handle remove SV (remove from `user.sv_ids`, optionally delete SV entity)

**Special Considerations**:

- SV creation requires backend API endpoint
- Need to fetch BOAT details when displaying SV list
- May need to join SV data with BOAT data for display

#### 6. Routes (MODIFY)

**File**: `client/src/routes/account.js`

**Changes**:

1. Import new components: `Organizations`, `Clubs`, `SVs`
2. Add three route objects:
   ```javascript
   {
     path: '/account/organizations',
     view: Organizations,
     layout: 'account',
     permission: 'user',
     title: 'account.index.title'
   },
   // ... clubs and svs
   ```

#### 7. Navigation Layout (MODIFY)

**File**: `client/src/components/layout/account/account.jsx`

**Changes**:

1. Add three items to `subnav` array:
   ```javascript
   {
     label: t('account.nav.organizations'),
     link: '/account/organizations',
     icon: 'building',
     permission: 'user'
   },
   // ... clubs and svs
   ```

#### 8. Account Index (MODIFY)

**File**: `client/src/views/account/index.jsx`

**Changes**:

1. Add three `Card` components for Organizations, Clubs, SVs
2. Use appropriate icons: `building`, `users`, `ship`
3. Link to respective routes

### Backend Files

#### 9. User Controller (MODIFY)

**File**: `server/controller/user.controller.js`

**Changes Required**:

1. Update Joi validation schema in `exports.update`:

   ```javascript
   org_ids: joi.array().items(joi.string()).optional(),
   club_ids: joi.array().items(joi.string()).optional(),
   sv_ids: joi.array().items(joi.string()).optional(),
   ```

2. Add validation logic (optional but recommended):

   - Verify that `org_ids` contain valid organization IDs
   - Verify that `club_ids` contain valid club IDs
   - Verify that `sv_ids` contain valid SV IDs
   - This prevents invalid IDs from being saved

3. Ensure update logic handles arrays correctly:
   - Arrays are replaced (not merged) when provided
   - Empty arrays are allowed (user removes all items)

**Validation Approach**:

```javascript
// Option 1: Basic validation (just check array of strings)
org_ids: joi.array().items(joi.string()).optional();

// Option 2: Validate IDs exist (more robust, but requires DB queries)
// This would need to check org/club/sv models
```

### Locale Files

#### 10. Profile Locales (MODIFY)

**File**: `client/src/locales/en/account/en_profile.json`

**Add**:

```json
{
  "sections": {
    "user_info": "Your Information",
    "account_info": "Account Information"
  },
  "form": {
    "name": {
      "label": "Your Name",
      "error": "Name is required"
    },
    "email": {
      "label": "Email address",
      "error": "Email is required"
    },
    "phone": {
      "label": "Phone"
    },
    "address": {
      "label": "Address",
      "error": "Address is required"
    },
    "avatar": {
      "label": "Profile Picture"
    },
    "account_name": {
      "label": "Account Name"
    },
    "default_account_id": {
      "label": "Default Account"
    },
    "button": "Save"
  }
}
```

**Note**: Reuse locale keys from `en_users.json` for detail fields (`name_.prefix`, `email_.primary`, etc.)

#### 11. Organizations Locales (CREATE)

**File**: `client/src/locales/en/account/en_organizations.json`

**Content**: See design document section 3.7.2

#### 12. Clubs Locales (CREATE)

**File**: `client/src/locales/en/account/en_clubs.json`

**Content**: See design document section 3.7.3

#### 13. SVs Locales (CREATE)

**File**: `client/src/locales/en/account/en_svs.json`

**Content**: See design document section 3.7.4 (updated: "Sailing Vessels" not "Sailboats/Vessels")

#### 14. Navigation Locales (MODIFY)

**File**: `client/src/locales/en/en_nav.json`

**Add**:

```json
{
  "account": {
    "nav": {
      "organizations": "Organizations",
      "clubs": "Clubs",
      "svs": "SVs (Boats)"
    }
  }
}
```

---

## Data Flow Diagrams

### Profile Page Form Submission

```
User edits fields
    ↓
React Hook Form state updates
    ↓
User clicks Save
    ↓
Form validation (client-side)
    ↓
Assemble data:
  - name_ → name (via helper)
  - email_.primary → email
  - phone_.primary → phone (E.164 format)
  - address_ → address (via helper)
    ↓
PATCH /api/user
    ↓
Backend validation (Joi)
    ↓
Backend assembly (if needed)
    ↓
Model update (MongoDB)
    ↓
Response with updated user
    ↓
Update authContext
    ↓
Show success notification
```

### Organizations Page Add Flow

```
User clicks "+" button
    ↓
Fetch available organizations (GET /api/org)
    ↓
Display dropdown/popover
    ↓
User selects organization
    ↓
Add org_id to selectedOrgIds state
    ↓
Update UI (organization appears in list)
    ↓
User clicks Save
    ↓
PATCH /api/user { org_ids: selectedOrgIds }
    ↓
Backend validation
    ↓
Update user.org_ids array
    ↓
Response with updated user
    ↓
Update local state
    ↓
Show success notification
```

### SVs Page Add Flow (BOAT → SV)

```
User clicks "+" button
    ↓
Fetch available BOATs (GET /api/boat)
    ↓
Display dropdown/popover
    ↓
User selects BOAT
    ↓
Create SV entity:
  POST /api/sv {
    boat_id: selectedBoat.id,
    user_ids: { owner: current_user.id }
  }
    ↓
SV created, returns sv.id
    ↓
Add sv.id to selectedSvIds state
    ↓
Update UI (SV appears in list)
    ↓
User clicks Save
    ↓
PATCH /api/user { sv_ids: selectedSvIds }
    ↓
Backend validation
    ↓
Update user.sv_ids array
    ↓
Response with updated user
    ↓
Update local state
    ↓
Show success notification
```

---

## Security Considerations

### 1. Input Validation

**Frontend**:

- Validate required fields (address)
- Validate email format
- Validate phone format (E.164)
- Sanitize user input

**Backend**:

- Joi validation for all fields
- Validate `org_ids`, `club_ids`, `sv_ids` arrays contain valid IDs
- Prevent SQL injection / NoSQL injection (MongoDB handles this, but validate types)
- Verify user can only update their own profile (unless admin)

### 2. Authorization

**Profile Page**:

- User can only update their own profile
- Account name update requires `owner` permission
- Default account selection requires multiple accounts

**Organizations/Clubs/SVs Pages**:

- User can only manage their own `org_ids`, `club_ids`, `sv_ids`
- Verify IDs exist in respective collections before adding
- Prevent adding invalid IDs

### 3. Data Integrity

**SV Creation**:

- Verify BOAT exists before creating SV
- Verify user has permission to claim ownership
- Prevent duplicate SV creation (same user + same boat)

**Array Updates**:

- Ensure arrays are properly validated
- Handle empty arrays correctly
- Prevent null/undefined arrays

### 4. XSS Prevention

- Escape user input (already handled in model layer)
- Use React's built-in XSS protection
- Validate and sanitize all user-provided data

---

## Questions for Clarification

### Critical Questions (Must Answer Before Implementation)

1. **API Endpoints for Fetching Available Items**:

   - Do `/api/org`, `/api/club`, `/api/boat` endpoints exist?
   - If not, what endpoints should be used?
   - What is the response format?
   - Do they require authentication?
   - Are there any filters/query parameters needed?

2. **SV Creation API**:

   - Does POST `/api/sv` endpoint exist?
   - What is the request format?
   - What fields are required?
   - What is the response format?
   - Should SV creation happen automatically when user selects BOAT, or on form submit?

3. **SV Display**:

   - When displaying user's SVs, should we fetch full SV details (including BOAT info)?
   - Should we join SV data with BOAT data for display?
   - What information should be shown for each SV in the list? (boat name only? boat name + owners? boat name + certs?)

4. **Organization/Club/SV Removal**:

   - When user removes an SV, should we:
     a) Just remove it from `user.sv_ids` array?
     b) Delete the SV entity entirely?
     c) Keep SV but remove user from `sv.user_ids`?
   - Same question for organizations and clubs (though they're simpler - just remove from array)

5. **Dropdown/Popover Component**:

   - What component should be used for the "+" button dropdown?
   - Should it be:
     a) Radix UI Popover with Select inside?
     b) Custom dropdown component?
     c) Existing Select component with custom trigger?
   - Should it be searchable/filterable?

6. **Address Field Requirement**:

   - Is address field required for all users, or only certain user types?
   - Should the requirement be enforced on the backend as well?

7. **ProfileCollapsibleField vs CollapsibleSettingRow**:

   - Should we create a new component, or extend `CollapsibleSettingRow` with a prop to control label position?
   - What's the preferred approach for code reuse?

8. **Backend Validation**:

   - Should backend validate that `org_ids`, `club_ids`, `sv_ids` contain valid IDs?
   - Or is it acceptable to just validate they're arrays of strings?
   - If validation is needed, should it be synchronous (slower) or can invalid IDs be cleaned up later?

9. **Error Handling**:

   - What should happen if user tries to add an organization/club/SV that doesn't exist?
   - What should happen if SV creation fails but user has already added it to their list?
   - How should we handle network errors during save?

10. **Loading States**:
    - Should we show loading indicators when fetching available organizations/clubs/boats?
    - Should we disable form submission while saving?

### Nice-to-Have Questions (Can Be Decided During Implementation)

11. **Search/Filter**:

    - Should the dropdown be searchable for organizations/clubs/boats?
    - Should there be pagination if there are many items?

12. **Help Cards**:

    - What exact content should be in help cards?
    - Should they be dismissible?

13. **Empty States**:

    - What should be displayed when user has no organizations/clubs/SVs?
    - Should there be a call-to-action to add the first one?

14. **Confirmation Dialogs**:

    - Should removing an organization/club/SV require confirmation?
    - Or is undo functionality preferred?

15. **Bulk Operations**:
    - Should users be able to add multiple organizations/clubs/boats at once?
    - Or one at a time only?

---

## Implementation Order

### Phase 1: Profile Page Refactor (Foundation)

1. Create `ProfileCollapsibleField` component
2. Refactor Profile page to use new component
3. Test accordion behavior
4. Test form submission
5. Update locales

### Phase 2: Backend Support

6. Update user controller validation
7. Test backend accepts `org_ids`, `club_ids`, `sv_ids`
8. Verify API endpoints exist (or create them)

### Phase 3: Organizations Page

9. Create Organizations page component
10. Implement "+" dropdown functionality
11. Implement add/remove logic
12. Test form submission
13. Add routes and navigation

### Phase 4: Clubs Page

14. Create Clubs page (copy Organizations pattern)
15. Update for clubs-specific logic
16. Test

### Phase 5: SVs Page

17. Create SVs page
18. Implement BOAT selection → SV creation flow
19. Test SV creation and display
20. Handle edge cases

### Phase 6: Polish

21. Add help cards
22. Add loading states
23. Add error handling
24. Add empty states
25. Final testing

---

## Testing Checklist

### Profile Page

- [ ] Accordion expands/collapses correctly
- [ ] Display fields update in real-time
- [ ] Email/phone clicks open accordion (not mailto/tel)
- [ ] Address field shows error when empty and required
- [ ] Form submission works
- [ ] authContext updates on save
- [ ] Visual separation between sections is clear

### Organizations Page

- [ ] Page loads and displays user's organizations
- [ ] "+" button shows dropdown
- [ ] Dropdown shows available organizations
- [ ] Selecting organization adds it to list
- [ ] Remove button removes organization
- [ ] Form submission updates `org_ids`
- [ ] Help card displays correctly

### Clubs Page

- [ ] Same as Organizations, but for clubs

### SVs Page

- [ ] Page loads and displays user's SVs
- [ ] "+" button shows dropdown of BOATs
- [ ] Selecting BOAT creates SV
- [ ] SV appears in list
- [ ] Remove button removes SV
- [ ] Form submission updates `sv_ids`
- [ ] Help card explains BOAT vs SV relationship

### Navigation

- [ ] Account index shows all three cards
- [ ] Cards link to correct pages
- [ ] Subnav shows all three menu items
- [ ] Menu items link to correct pages

### Backend

- [ ] User controller accepts `org_ids`, `club_ids`, `sv_ids`
- [ ] Validation works correctly
- [ ] Arrays are saved correctly
- [ ] Empty arrays are handled correctly

---

## Risk Assessment

### High Risk

- **SV Creation Flow**: Complex entity relationship (USER + BOAT → SV) may have edge cases
- **API Endpoints**: If endpoints don't exist, need to create them (adds scope)

### Medium Risk

- **ProfileCollapsibleField Component**: New component needs thorough testing
- **Backend Validation**: Need to ensure validation doesn't break existing functionality

### Low Risk

- **Organizations/Clubs Pages**: Straightforward implementation following existing patterns
- **Routes/Navigation**: Simple additions following existing patterns

---

## Estimated Effort

- **ProfileCollapsibleField Component**: 4-6 hours
- **Profile Page Refactor**: 6-8 hours
- **Organizations Page**: 4-6 hours
- **Clubs Page**: 3-4 hours (reuse Organizations pattern)
- **SVs Page**: 6-8 hours (more complex due to SV creation)
- **Backend Updates**: 2-3 hours
- **Routes/Navigation**: 1-2 hours
- **Locales**: 1-2 hours
- **Testing**: 4-6 hours

**Total Estimated Effort**: 31-45 hours

---

## Dependencies

### External Dependencies

- `@radix-ui/react-collapsible` (already exists)
- `react-hook-form` (already exists)

### Internal Dependencies

- `CollapsibleSettingRow` component (for reference/pattern)
- `UserEditForm` component (for reference/pattern)
- `Notifications` page (for reference/pattern)
- User controller (needs modification)
- API endpoints for org/club/boat/sv (may need creation)

---

## Success Criteria

1. ✅ Profile page uses accordion fields with label-above, full-width display
2. ✅ Email/phone clicks open accordion (not mailto/tel)
3. ✅ Address field is required with error message
4. ✅ Organizations page allows adding/removing organizations via "+" dropdown
5. ✅ Clubs page allows adding/removing clubs via "+" dropdown
6. ✅ SVs page allows claiming BOAT ownership (creates SV) via "+" dropdown
7. ✅ All pages save changes correctly
8. ✅ Navigation works (cards and menu items)
9. ✅ Backend accepts and validates `org_ids`, `club_ids`, `sv_ids`
10. ✅ All tests pass

---

**END OF IMPLEMENTATION PLAN**
