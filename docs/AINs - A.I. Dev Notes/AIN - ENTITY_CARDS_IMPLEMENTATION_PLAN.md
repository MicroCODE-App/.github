# AIN - Entity Cards Implementation Plan

## Document Information

- **Created**: 2024
- **Status**: Planning Phase
- **Feature**: Entity Cards Display for Manage {Entity} Dialogs
- **Priority**: Medium

---

## 1. Executive Summary

### 1.1 Overview

This document outlines the implementation plan for adding Entity Cards to the right side of "Manage {Entity}" dialogs. These cards will display detailed information about entities (Organizations, Clubs, Sailing Vessels) that a user is connected to, including their logo, contact information, and other relevant details.

### 1.2 Scope

- **Entities Affected**: Organizations (`org`), Clubs (`club`), Sailing Vessels (`sv`)
- **Frontend Components**: `organizations.jsx`, `clubs.jsx`, `svs.jsx`
- **Backend APIs**: Organization, Club, and Sailing Vessel list endpoints
- **New Components**: Reusable Entity Card component

### 1.3 Goals

1. Display detailed entity information in card format to the right of the "Manage {Entity}" form
2. Show entity logo in upper right corner of each card (preserving aspect ratio)
3. Display entity details: acronym, name, description, address, phone(s), email(s)
4. Maintain responsive design and consistent styling with existing UI
5. Ensure performance with proper data fetching and caching

---

## 2. Current Architecture Analysis

### 2.1 Existing Structure

#### 2.1.1 Frontend Components

- **Location**: `client/src/views/account/`
- **Files**:
  - `organizations.jsx` - Manages user's organizations
  - `clubs.jsx` - Manages user's clubs
  - `svs.jsx` - Manages user's sailing vessels (assumed similar structure)

#### 2.1.2 Current Layout Structure

```
<Animate>
  <Row width='lg'>
    <Card title="Manage {Entity}">
      {/* Help Card */}
      {/* Conditional: Empty State or Non-Empty State */}
      {/* Current Entities List */}
      {/* Action Buttons */}
      {/* Save Button */}
    </Card>
  </Row>
</Animate>
```

#### 2.1.3 Current Data Flow

1. User data fetched via `useAPI('/api/user', 'get', refreshTrigger)`
2. Entity IDs stored in user object: `org_ids`, `club_ids`, `sv_ids`
3. Entity list fetched via `/api/org`, `/api/club`, `/api/sv` with search
4. Current list endpoint returns: `id`, `acronym`, `name`, `logo` only

### 2.2 Backend Structure

#### 2.2.1 Models

- **Location**: `server/model/mongo/`
- **Files**:
  - `org.mongo.js` - Organization schema
  - `club.mongo.js` - Club schema
  - `sv.mongo.js` - Sailing Vessel schema

#### 2.2.2 Schema Fields Available

**Organizations & Clubs**:

- `id`, `key`, `name`, `acronym`
- `description`
- `email`, `email_` (object with multiple emails)
- `phone`, `phone_` (object with multiple phones)
- `address`, `address_` (object with structured address)
- `logo` (SVG string)

**Sailing Vessels**:

- `id`, `key`, `name`, `display`
- `description`
- `boat_key`, `boat_id`
- Note: Sailing Vessels may not have the same contact fields as Organizations/Clubs

#### 2.2.3 Controllers

- **Location**: `server/controller/`
- **Files**:
  - `org.controller.js` - `list()` method returns limited fields
  - `club.controller.js` - `list()` method returns limited fields
  - `sv.controller.js` - (needs investigation)

#### 2.2.4 Current API Response

```javascript
// GET /api/org?search=...
{
  data: [
    {
      id: "...",
      acronym: "DRYA",
      name: "Detroit Regional Yacht-Racing Association",
      logo: "<svg>...</svg>",
    },
  ];
}
```

**Missing Fields**: `description`, `address`, `phone`, `email`, `phone_`, `email_`, `address_`

---

## 3. Design Specifications

### 3.1 Card Layout

```
┌──────────────────────────────────────────────────────┐
│                                    ┌──────────────┐  │
│  {Entity}: {Acronym}               │              │  │
│  (Large, Bold White/Black)         │    LOGO      │  │
│                                    │  (Square,    │  │
│  Name: {Entity Name}               │   Aspect     │  │
│  (Smaller Gray)                    │   Preserved) │  │
│                                    │              │  │
│  Description: {Description}        │              │  │
│  (Gray, same size as Name)         └──────────────┘  │
│                                                      │
│  Address: {Formatted Address}                        │
│  (Gray, same size as Name)                           │
│                                                      │
│  Phone(s): {Phone List}                              │
│  (Gray, same size as Name)                           │
│                                                      │
│  Email(s): {Email List}                              │
│  (Gray, same size as Name)                           │
└──────────────────────────────────────────────────────┘
```

### 3.2 Visual Specifications

#### 3.2.1 Card Container

- **Background**: Dark theme compatible (matches existing Card component)
- **Border**: `border-slate-200 dark:border-slate-800`
- **Padding**: Consistent with existing Card component
- **Shadow**: `shadow-sm` (matching Card component)
- **Border Radius**: `rounded-lg` (matching Card component)

#### 3.2.2 Typography

- **Entity Header**:

  - Format: `{Entity Type}: {Acronym}` (e.g., "Organization: DRYA")
  - Size: Large (text-xl or text-2xl)
  - Weight: Bold (font-bold)
  - Color: White/Black (text-slate-950 dark:text-slate-50)

- **Field Labels & Values**:
  - Label: "Name:", "Description:", etc.
  - Size: Base (text-base)
  - Color: Gray (text-slate-600 dark:text-slate-400)
  - Weight: Normal

#### 3.2.3 Logo Display

- **Position**: Upper right corner
- **Container**: Square container with fixed aspect ratio
- **Size**: Suggested 64x64px or 80x80px
- **Aspect Ratio**: Preserved (object-fit: contain)
- **Background**: Transparent or matching card background
- **Rendering**: SVG content rendered directly (dangerouslySetInnerHTML or SVG component)

#### 3.2.4 Responsive Behavior & Layout

- **Large View (lg - Desktop/Client)**:

  - Cards displayed in flex container to the right of Manage form
  - Cards flex to fill container width with padding
  - Display 2-3 cards across (responsive flex-wrap)
  - Cards container uses flexbox with gap spacing
  - Layout: Two-column (form left, cards right) using grid or flex

- **Small View (sm - Mobile/App)**:
  - Cards displayed below Manage form (single column)
  - One card per row (full width)
  - Cards container scrollable (user scrolls down to view cards)
  - Layout: Single column stack (form top, cards below)

### 3.3 Data Formatting

#### 3.3.1 Address Formatting

- **If `address_` object exists**: Format structured address
  - Format: `{street}, {city}, {state} {zip}, {country}`
  - Handle missing fields gracefully
- **If only `address` string exists**: Display as-is
- **If neither exists**: Display "N/A" or omit field

#### 3.3.2 Phone Formatting

- **If `phone_` object exists**: Display all phone numbers
  - Format: `Primary: {primary}, Work: {work}, ...`
  - Or display as list: `• {primary}\n• {work}`
- **If only `phone` string exists**: Display as-is
- **If neither exists**: Display "N/A" or omit field

#### 3.3.3 Email Formatting

- **If `email_` object exists**: Display all emails
  - Format: `Primary: {primary}, Work: {work}, ...`
  - Or display as list: `• {primary}\n• {work}`
- **If only `email` string exists**: Display as-is
- **If neither exists**: Display "N/A" or omit field

---

## 4. Implementation Plan

### 4.1 Phase 1: Backend API Updates

#### 4.1.1 Update Organization Controller

**File**: `server/controller/org.controller.js`

**Changes**:

- Modify `list()` method to include additional fields in select
- Current: `.select('id acronym name logo')`
- New: `.select('id acronym name description email email_ phone phone_ address address_ logo')`

**Impact**:

- Increases response payload size
- May require pagination for large datasets (future consideration)

#### 4.1.2 Update Club Controller

**File**: `server/controller/club.controller.js`

**Changes**:

- Same as Organization Controller
- Modify `list()` method to include additional fields

#### 4.1.3 Update Sailing Vessel Controller

**File**: `server/controller/sv.controller.js`

**Changes**:

- Investigate current structure
- Determine if SV has similar fields or needs different handling
- May need to join with `boat` table for additional information

**Questions**:

- Do Sailing Vessels have contact information?
- Should SV cards display boat information instead?

### 4.2 Phase 2: Create Reusable Entity Card Component

#### 4.2.1 Component Structure

**File**: `client/src/components/entitycard/entitycard.jsx`

**Props Interface**:

```typescript
interface EntityCardProps {
  entity: {
    id: string;
    acronym?: string;
    name: string;
    description?: string;
    address?: string;
    address_?: {
      street?: string;
      city?: string;
      state?: string;
      zip?: string;
      country?: string;
      [key: string]: any;
    };
    phone?: string;
    phone_?: {
      primary?: string;
      work?: string;
      [key: string]: string;
    };
    email?: string;
    email_?: {
      primary?: string;
      work?: string;
      [key: string]: string;
    };
    logo?: string;
  };
  entityType: "organization" | "club" | "sailing-vessel";
  className?: string;
}
```

**Component Features**:

1. Format and display entity header with type and acronym
2. Render logo in upper right corner
3. Format and display all contact fields
4. Handle missing/null values gracefully
5. Support dark mode
6. Responsive design

#### 4.2.2 Helper Functions

**File**: `client/src/components/entitycard/entitycard.utils.js`

**Functions**:

- `formatAddress(address, address_)` - Format address from string or object
- `formatPhones(phone, phone_)` - Format phone list
- `formatEmails(email, email_)` - Format email list
- `formatEntityHeader(entityType, acronym)` - Format header text

### 4.3 Phase 3: Update View Components

#### 4.3.1 Update Organizations View

**File**: `client/src/views/account/organizations.jsx`

**Changes**:

1. Modify layout to support two-column layout (form + cards)
2. Fetch full entity details for connected organizations
3. Render EntityCard components for each connected organization
4. Handle loading states
5. Handle empty states (no cards when no organizations)

**Layout Structure**:

**Current Structure** (no wrapper exists):

```jsx
<Row width="lg">
  <Card title={t("account.organizations.subtitle")} loading={loading}>
    {/* Existing form content */}
  </Card>
</Row>
```

**New Structure** (add wrapper divs for layout):

```jsx
<Row width="lg">
  {/* NEW: Flex container for two-column layout */}
  <div className="flex flex-col lg:flex-row gap-6">
    {/* NEW: Form Container wrapper - wraps existing Card */}
    <div className="flex-1">
      <Card title={t("account.organizations.subtitle")} loading={loading}>
        {/* Existing form content - NO CHANGES to Card content */}
      </Card>
    </div>

    {/* NEW: Entity Cards Container */}
    <div className="flex-1 lg:flex lg:flex-wrap lg:gap-4 lg:items-start">
      {currentOrgs.map((org) => (
        <div
          key={org.id}
          className="flex-1 lg:flex-[0_1_calc(50%-0.5rem)] xl:flex-[0_1_calc(33.333%-0.67rem)] min-w-0"
        >
          <EntityCard
            entity={org}
            entityType="organization"
            className="h-full"
          />
        </div>
      ))}
    </div>
  </div>
</Row>
```

**Important Note**: The "Form Container" (`<div className="flex-1">`) does NOT exist in current code and must be added. The existing `Card` component and all its internal content remain unchanged - we're just wrapping it in container divs for the flex layout.

**Card Container Styling**:

- Cards use flexbox to fill container with padding
- Large view: `flex flex-wrap gap-4` - allows 2-3 cards across
- Small view: `flex-col` - single column, scrollable below form
- Each card wrapper: `flex-1` with responsive flex-basis for 2-3 columns
- Cards have consistent padding and fill their flex container

#### 4.3.2 Update Clubs View

**File**: `client/src/views/account/clubs.jsx`

**Changes**:

- Same as Organizations View
- Replace "organization" with "club" in EntityCard props

#### 4.3.3 Update Sailing Vessels View

**File**: `client/src/views/account/svs.jsx`

**Changes**:

- Investigate current structure
- Adapt to SV-specific fields
- May need different card layout if SV structure differs

### 4.4 Phase 4: Data Fetching Optimization

#### 4.4.1 Current Approach

- Entities fetched via search endpoint
- Only returns limited fields
- Need to fetch full details for connected entities

#### 4.4.2 Proposed Approach

**Option A**: Fetch full details when loading connected entities

- Use existing list endpoint with empty search
- Filter to only connected entity IDs
- Pros: Simple, uses existing endpoint
- Cons: Fetches all entities, then filters

**Option B**: Create new endpoint for fetching multiple entities by IDs

- New endpoint: `GET /api/org/bulk?ids=id1,id2,id3`
- Pros: Efficient, only fetches needed entities
- Cons: Requires new endpoint

**Option C**: Enhance user endpoint to include full entity details

- Modify `/api/user` to populate entity details
- Pros: Single request, always up-to-date
- Cons: Increases user endpoint payload, may be slow

**Recommendation**: Start with Option A, optimize to Option B if performance issues arise.

### 4.5 Phase 5: Styling and Responsive Design

#### 4.5.1 Responsive Breakpoints

- **Small View (sm - Mobile/App)**:

  - Single column layout
  - Form on top, cards below (scrollable)
  - Cards: `flex-col` - one card per row, full width

- **Large View (lg - Desktop/Client)**:
  - Two-column flex layout (form left, cards right)
  - Cards container: `flex flex-wrap gap-4`
  - Cards: 2-3 cards across using flex-basis
  - Breakpoint: Tailwind `lg:` (1024px+)

#### 4.5.2 Flex Layout Structure

```css
/* Container */
flex flex-col lg:flex-row gap-6

/* Cards Container (lg view) */
flex flex-wrap gap-4 items-start

/* Individual Card Wrapper */
flex-1 lg:flex-[0_1_calc(50%-0.5rem)] xl:flex-[0_1_calc(33.333%-0.67rem)]
min-w-0 (prevents overflow)

/* Card Component */
h-full (fills wrapper height)
p-6 (consistent padding)
```

#### 4.5.3 Card Sizing & Padding

- Cards flex to fill container with consistent padding
- Large view: 2 cards at `lg` breakpoint, 3 cards at `xl` breakpoint
- Small view: Full width cards, scrollable container
- Height: Auto-adjusts based on content
- Padding: Consistent with existing Card component (`p-6`)
- Gap spacing: `gap-4` between cards

---

## 5. Affected Files Summary

### 5.1 Backend Files

#### 5.1.1 Controllers (Modify)

- `server/controller/org.controller.js`
- `server/controller/club.controller.js`
- `server/controller/sv.controller.js` (investigate first)

#### 5.1.2 Routes (No changes expected)

- `server/api/org.route.js`
- `server/api/club.route.js`
- `server/api/sv.route.js`

#### 5.1.3 Models (No changes expected)

- `server/model/mongo/org.mongo.js`
- `server/model/mongo/club.mongo.js`
- `server/model/mongo/sv.mongo.js`

### 5.2 Frontend Files

#### 5.2.1 New Components (Create)

- `client/src/components/entitycard/entitycard.jsx`
- `client/src/components/entitycard/entitycard.utils.js` (optional)

#### 5.2.2 View Components (Modify)

- `client/src/views/account/organizations.jsx`
- `client/src/views/account/clubs.jsx`
- `client/src/views/account/svs.jsx`

#### 5.2.3 Component Library (No changes expected)

- `client/src/components/card/card.jsx` (may reference for styling)
- `client/src/components/row/row.jsx` (may need width adjustment)

### 5.3 Translation Files (May need updates)

- `client/src/locales/en/account/en_organizations.json`
- `client/src/locales/en/account/en_clubs.json`
- `client/src/locales/en/account/en_svs.json`

**New Translation Keys Needed**:

- `entity_card.name`
- `entity_card.description`
- `entity_card.address`
- `entity_card.phone`
- `entity_card.email`
- `entity_card.no_data` (for missing fields)

---

## 6. Interface Contracts

### 6.1 API Response Contract

#### 6.1.1 Organization/Club List Response

```typescript
interface EntityListResponse {
  data: Array<{
    id: string;
    acronym?: string;
    name: string;
    description?: string;
    email?: string;
    email_?: {
      primary?: string;
      work?: string;
      [key: string]: string;
    };
    phone?: string;
    phone_?: {
      primary?: string;
      work?: string;
      [key: string]: string;
    };
    address?: string;
    address_?: {
      street?: string;
      city?: string;
      state?: string;
      zip?: string;
      country?: string;
      [key: string]: any;
    };
    logo?: string;
  }>;
}
```

### 6.2 Component Props Contract

#### 6.2.1 EntityCard Component

```typescript
interface EntityCardProps {
  entity: EntityData;
  entityType: "organization" | "club" | "sailing-vessel";
  className?: string;
}

interface EntityData {
  id: string;
  acronym?: string;
  name: string;
  description?: string;
  address?: string;
  address_?: AddressObject;
  phone?: string;
  phone_?: PhoneObject;
  email?: string;
  email_?: EmailObject;
  logo?: string;
}
```

---

## 7. User Stories

### 7.1 As a User

1. **As a user**, I want to see detailed information about my connected organizations/clubs/vessels in cards, so I can quickly reference their contact information without leaving the page.

2. **As a user**, I want to see entity logos in the cards, so I can visually identify entities quickly.

3. **As a user**, I want the cards to be displayed next to the management form, so I can manage and view entities in the same view.

4. **As a user**, I want the cards to be responsive, so I can use the feature on mobile devices.

### 7.2 As a Developer

1. **As a developer**, I want a reusable EntityCard component, so I can use it across different entity types.

2. **As a developer**, I want the component to handle missing data gracefully, so the UI doesn't break with incomplete entity data.

3. **As a developer**, I want the API to return all necessary fields, so I don't need multiple requests to display entity details.

---

## 8. Questions for Clarification

### 8.1 Data Structure Questions

1. **Sailing Vessels Structure**:

   - Do Sailing Vessels have contact information (email, phone, address)?
   - Should SV cards display boat information instead of contact info?
   - What fields should be displayed for Sailing Vessels?

2. **Logo Format**:

   - Are logos always SVG strings?
   - What should happen if a logo is missing or invalid?
   - Should there be a default placeholder logo?

3. **Address Format**:

   - What is the exact structure of `address_` object?
   - Are there other address fields beyond street, city, state, zip, country?
   - Should we display the structured `address_` or the string `address` when both exist?

4. **Phone/Email Format**:
   - What are all possible keys in `phone_` and `email_` objects?
   - Should we display all keys or only specific ones (primary, work)?
   - How should we format phone numbers (with dashes, parentheses, etc.)?

### 8.2 UI/UX Questions

5. **Card Layout**:

   - Should cards be scrollable if there are many entities?
   - What is the maximum number of cards to display before scrolling?
   - Should cards be in a single column or grid on desktop?

6. **Empty States**:

   - What should be displayed when there are no connected entities?
   - Should the cards section be hidden or show a message?

7. **Loading States**:

   - Should cards show loading skeletons while fetching data?
   - How should we handle slow API responses?

8. **Responsive Behavior**:
   - At what breakpoint should cards move below the form?
   - Should cards maintain side-by-side layout on tablets?

### 8.3 Performance Questions

9. **Data Fetching**:

   - Should we fetch full entity details immediately or lazy load?
   - Should we cache entity data to avoid refetching?
   - How many entities can a user typically have connected?

10. **API Optimization**:
    - Should we create a bulk fetch endpoint for multiple entities?
    - Should we paginate entity lists if they become large?

### 8.4 Styling Questions

11. **Card Styling**:

    - Should cards match the existing Card component styling exactly?
    - Should cards have hover effects or be static?
    - Should cards be clickable/navigable to entity detail pages?

12. **Logo Display**:
    - What size should logos be (64x64, 80x80, other)?
    - Should logos have a background color or be transparent?
    - Should logos be clickable to view full size?

---

## 9. Implementation Steps (Detailed)

### Step 1: Investigation & Clarification

1. Review `svs.jsx` to understand Sailing Vessel structure
2. Review `sv.controller.js` to understand SV API
3. Review seed data for all entity types to understand data structure
4. Get answers to clarification questions
5. Document findings

### Step 2: Backend API Updates

1. Update `org.controller.js` list method to include all fields
2. Update `club.controller.js` list method to include all fields
3. Investigate and update `sv.controller.js` if needed
4. Test API endpoints return correct data
5. Update API documentation if needed

### Step 3: Create EntityCard Component

1. Create `entitycard` directory in components
2. Create `entitycard.jsx` component file
3. Create helper utility functions for formatting
4. Implement logo rendering (SVG support)
5. Implement all field displays with proper formatting
6. Add dark mode support
7. Add responsive styling
8. Test component with sample data

### Step 4: Update Organizations View

1. Modify layout to support two-column grid
2. Add data fetching for full entity details
3. Integrate EntityCard component
4. Handle loading and empty states
5. Test with real data
6. Verify responsive behavior

### Step 5: Update Clubs View

1. Apply same changes as Organizations View
2. Test with real data
3. Verify consistency with Organizations View

### Step 6: Update Sailing Vessels View

1. Investigate SV-specific requirements
2. Adapt EntityCard or create SV-specific variant if needed
3. Apply changes similar to Organizations/Clubs
4. Test with real data

### Step 7: Testing & Refinement

1. Test all three entity types
2. Test with various data scenarios (missing fields, etc.)
3. Test responsive behavior on different screen sizes
4. Test dark mode
5. Performance testing (many entities)
6. Fix any bugs or issues

### Step 8: Documentation & Cleanup

1. Update component documentation
2. Add JSDoc comments
3. Clean up unused code
4. Update translation files if needed
5. Create/update tests if applicable

---

## 10. Risk Assessment

### 10.1 Technical Risks

1. **Performance Risk**: Fetching full entity details may slow down page load

   - **Mitigation**: Implement lazy loading or caching
   - **Impact**: Medium

2. **Data Consistency Risk**: Entity data may be incomplete or inconsistent

   - **Mitigation**: Handle missing fields gracefully in component
   - **Impact**: Low

3. **Responsive Design Risk**: Cards may not work well on mobile
   - **Mitigation**: Test thoroughly on all screen sizes
   - **Impact**: Medium

### 10.2 UX Risks

1. **Information Overload**: Too many cards may overwhelm users

   - **Mitigation**: Implement scrolling or pagination if needed
   - **Impact**: Low

2. **Layout Confusion**: Two-column layout may confuse users
   - **Mitigation**: Clear visual separation, proper spacing
   - **Impact**: Low

---

## 11. Success Criteria

### 11.1 Functional Requirements

- [ ] Entity cards display all required information
- [ ] Logos render correctly in upper right corner
- [ ] Cards appear to the right of Manage form on desktop
- [ ] Cards stack appropriately on mobile
- [ ] All three entity types (org, club, sv) work correctly

### 11.2 Non-Functional Requirements

- [ ] Page load time remains acceptable (< 2 seconds)
- [ ] Component is reusable and maintainable
- [ ] Code follows existing patterns and conventions
- [ ] Dark mode works correctly
- [ ] Responsive design works on all screen sizes

---

## 12. Future Enhancements (Out of Scope)

1. **Entity Detail Pages**: Clicking card navigates to full entity detail page
2. **Card Actions**: Add edit/remove buttons directly on cards
3. **Card Filtering/Sorting**: Filter or sort cards by various criteria
4. **Card Animations**: Add entrance animations for cards
5. **Bulk Operations**: Select multiple cards for bulk actions
6. **Card Customization**: User preferences for which fields to display

---

## 13. Diagrams

### 13.1 Component Hierarchy

```
Organizations View (organizations.jsx)
├── Row (width='lg')
    └── Flex Container (flex-col lg:flex-row)
        ├── Form Container (flex-1)
        │   └── Card (Manage Organizations Form)
        │       ├── Help Section
        │       ├── Current Organizations List
        │       ├── Action Buttons
        │       └── Save Button
        └── Cards Container (flex-1 lg:flex lg:flex-wrap)
            ├── Card Wrapper (flex-1 lg:flex-[0_1_calc(50%-0.5rem)])
            │   └── EntityCard (org 1)
            │       ├── Header (Organization: DRYA)
            │       ├── Logo (upper right)
            │       ├── Name
            │       ├── Description
            │       ├── Address
            │       ├── Phone(s)
            │       └── Email(s)
            ├── Card Wrapper (flex-1 lg:flex-[0_1_calc(50%-0.5rem)])
            │   └── EntityCard (org 2)
            └── Card Wrapper (flex-1 lg:flex-[0_1_calc(50%-0.5rem)])
                └── EntityCard (org 3)
```

### 13.2 Data Flow

```
User Component
    ↓ (useAPI hook)
GET /api/user
    ↓ (returns org_ids: ['id1', 'id2'])
GET /api/org?search=''
    ↓ (returns full org data)
Filter to connected orgs
    ↓
Render EntityCard components
```

### 13.3 Layout Structure (Large View - lg/Desktop)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Row (width='lg')                             │
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐ │
│  │  Form Container (flex-1)     │  │  Cards Container (flex-1)    │ │
│  │  ┌──────────────────────────┐│  │  ┌──────────┐  ┌──────────┐  │ │
│  │  │ Card: Manage Form        ││  │  │ Card 1   │  │ Card 2   │  │ │
│  │  │ ┌──────────────────────┐ ││  │  │ (flex)   │  │ (flex)   │  │ │
│  │  │ │ Help Section         │ ││  │  └──────────┘  └──────────┘  │ │
│  │  │ ├──────────────────────┤ ││  │  ┌──────────┐                │ │
│  │  │ │ Current List         │ ││  │  │ Card 3   │                │ │
│  │  │ ├──────────────────────┤ ││  │  │ (flex)   │                │ │
│  │  │ │ Action Buttons       │ ││  │  └──────────┘                │ │
│  │  │ ├──────────────────────┤ ││  │  (flex-wrap: 2-3 across)     │ │
│  │  │ │ Save Button          │ ││  │                              │ │
│  │  │ └──────────────────────┘ ││  │                              │ │
│  │  └──────────────────────────┘│  │                              │ │
│  └──────────────────────────────┘  └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### 13.4 Layout Structure (Small View - sm/Mobile)

```
┌─────────────────────────────────────────────┐
│         Row (width='sm')                    │
│  ┌────────────────────────────────────────┐ │
│  │  Form Container (flex-1)               │ │
│  │  ┌───────────────────────────────────┐ │ │
│  │  │ Card: Manage Form                 │ │ │
│  │  │ ┌────────────────────────────────┐│ │ │
│  │  │ │ Help Section                   ││ │ │
│  │  │ ├────────────────────────────────┤│ │ │
│  │  │ │ Current List                   ││ │ │
│  │  │ ├────────────────────────────────┤│ │ │
│  │  │ │ Action Buttons                 ││ │ │
│  │  │ ├────────────────────────────────┤│ │ │
│  │  │ │ Save Button                    ││ │ │
│  │  │ └────────────────────────────────┘│ │ │
│  │  └───────────────────────────────────┘ │ │
│  └────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────┐ │
│  │  Cards Container (flex-1 flex-col)     │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │ EntityCard (Org 1) - Full Width  │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │ EntityCard (Org 2) - Full Width  │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │ EntityCard (Org 3) - Full Width  │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │  (Scrollable - user scrolls down)      │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

---

## 14. Appendix

### 14.1 Example Entity Data Structures

#### Organization Example

```javascript
{
  id: "org_123",
  acronym: "DRYA",
  name: "Detroit Regional Yacht-Racing Association",
  description: "Founded in 1912...",
  email: "thedrya@gmail.com",
  email_: {
    primary: "thedrya@gmail.com",
    work: "thedrya@gmail.com"
  },
  phone: "15867781000",
  phone_: {
    primary: "15867781000",
    work: "15867781000"
  },
  address: "23915 Jefferson Avenue, Suite 1, St. Clair Shores, MI 48080, USA",
  address_: {
    street: "23915 Jefferson Avenue",
    suite: "Suite 1",
    city: "St. Clair Shores",
    state: "MI",
    zip: "48080",
    country: "USA"
  },
  logo: "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"64\" height=\"64\" viewBox=\"0 0 24 24\" fill=\"none\">...</svg>"
}
```

#### Club Example

```javascript
{
  id: "club_456",
  acronym: "BYC",
  name: "Bayview Yacht Club",
  description: "Founded in 1915...",
  email: "info@byc.com",
  email_: {
    primary: "info@byc.com",
    office: "matt@byc.com"
  },
  phone: "+13138221853",
  phone_: {
    primary: "+13138221853",
    office: "+13138221853;ext=105"
  },
  address: "100 Clairpointe Street, Detroit, MI 48215, USA",
  address_: {
    street: "100 Clairpointe Street",
    city: "Detroit",
    state: "MI",
    zip: "48215",
    country: "USA"
  },
  logo: "<svg>...</svg>"
}
```

### 14.2 Tailwind CSS Classes Reference

- Grid: `grid grid-cols-1 lg:grid-cols-2 gap-6`
- Spacing: `space-y-4` (vertical spacing)
- Text: `text-xl font-bold`, `text-base text-slate-600 dark:text-slate-400`
- Border: `border border-slate-200 dark:border-slate-800`
- Rounded: `rounded-lg`
- Shadow: `shadow-sm`

---

## 15. Plan Review & Confidence Assessment

### 15.1 Implementation Confidence Rating: **85%**

**Strengths**:

- ✅ Clear understanding of existing codebase structure
- ✅ Well-defined component architecture
- ✅ Backend API changes are straightforward (field additions)
- ✅ Frontend patterns align with existing codebase
- ✅ Responsive design approach is clear
- ✅ Data models are well understood

**Areas Requiring Clarification** (to reach 95%+ confidence):

- ⚠️ Sailing Vessel card content (different from org/club)
- ⚠️ Exact flex-basis calculations for 2-3 card layout
- ⚠️ Logo rendering approach (SVG string handling)
- ⚠️ Data fetching strategy confirmation
- ⚠️ Empty state handling for cards section

### 15.2 Remaining Questions for 95%+ Confidence

#### Critical Questions (Must Answer):

1. **Sailing Vessel Cards**:

   - What fields should SV cards display? (They don't have contact info like org/club)
   - Should SV cards show boat information (name, sail_no, etc.) instead?
   - Should SV cards have a different layout/structure?

2. **Logo Rendering**:

   - Are logos always valid SVG strings?
   - Should we use `dangerouslySetInnerHTML` or a safer SVG component?
   - What happens if logo is missing/null? Show placeholder or omit?
   - What size should logos be? (64x64, 80x80, or responsive?)

3. **Flex Layout Specifics**:

   - Exact flex-basis values for 2 cards at `lg` breakpoint?
   - Exact flex-basis values for 3 cards at `xl` breakpoint?
   - Should cards have min-width constraints?
   - Gap spacing preference: `gap-4` (1rem) or different?

4. **Data Fetching**:

   - Confirm Option A (fetch all, filter) is acceptable for initial implementation?
   - Typical number of entities per user? (affects performance)
   - Should we implement caching or is refetch acceptable?

5. **Empty States**:
   - When user has no connected entities, hide cards container entirely?
   - Or show empty state message in cards container?

#### Secondary Questions (Nice to Have):

6. **Phone/Email Formatting**:

   - Display all keys from `phone_`/`email_` objects or only specific ones?
   - Preferred format: list with bullets or comma-separated?

7. **Address Formatting**:

   - Use `address_` object when available, fallback to `address` string?
   - Handle all possible address\_ fields (suite, building, etc.)?

8. **Card Interactions**:

   - Should cards be clickable/navigable?
   - Any hover effects desired?

9. **Performance**:

   - Maximum expected entities per user?
   - Should we implement virtual scrolling if many entities?

10. **Translation Keys**:
    - Confirm translation key structure for entity types?
    - Need separate keys for "Organization:", "Club:", "Sailing Vessel:"?

### 15.3 Assumptions Made (Require Validation)

1. **Assumption**: Sailing Vessels will use similar card structure but with boat-related fields

   - **Risk**: Medium - May need different component variant
   - **Mitigation**: Create flexible EntityCard that adapts to entity type

2. **Assumption**: Logos are SVG strings stored directly in database

   - **Risk**: Low - Can handle different formats if needed
   - **Mitigation**: Add logo format detection and rendering logic

3. **Assumption**: Flex layout with calc() for responsive 2-3 card layout

   - **Risk**: Low - Standard Tailwind/CSS approach
   - **Mitigation**: Test on various screen sizes

4. **Assumption**: Option A data fetching (fetch all, filter) is acceptable

   - **Risk**: Medium - May be slow with many entities
   - **Mitigation**: Can optimize to Option B if needed

5. **Assumption**: Cards container scrolls naturally on mobile
   - **Risk**: Low - Standard browser behavior
   - **Mitigation**: Test on mobile devices

### 15.4 Implementation Readiness Checklist

- [x] Architecture understood
- [x] Component structure defined
- [x] API changes identified
- [x] Layout approach specified
- [x] Responsive design planned
- [ ] Sailing Vessel card content confirmed
- [ ] Logo rendering approach confirmed
- [ ] Flex layout specifics confirmed
- [ ] Data fetching strategy confirmed
- [ ] Empty state handling confirmed

### 15.5 Risk Assessment Summary

| Risk                              | Likelihood | Impact | Mitigation                          |
| --------------------------------- | ---------- | ------ | ----------------------------------- |
| SV cards need different structure | Medium     | Medium | Create flexible component           |
| Logo rendering issues             | Low        | Low    | Add format detection                |
| Performance with many entities    | Low        | Medium | Optimize to bulk endpoint if needed |
| Flex layout complexity            | Low        | Low    | Standard CSS approach               |
| Missing data handling             | Low        | Low    | Graceful fallbacks implemented      |

---

## 16. Approval & Next Steps

### 16.1 Review Checklist

- [x] Architecture reviewed
- [ ] Data structure questions answered (Section 15.2)
- [ ] UI/UX questions answered (Section 15.2)
- [ ] Implementation approach approved
- [x] Risks assessed and mitigated

### 16.2 Next Steps

1. **Answer critical questions** (Section 15.2, items 1-5)
2. **Review and approve this plan**
3. **Begin implementation** following steps in Section 9
4. **Regular check-ins** during implementation
5. **Testing and refinement** before deployment

### 16.3 Recommended Approach

**Phase 1 - Quick Wins** (Can start immediately):

- Update backend controllers (org, club) - straightforward
- Create EntityCard component with org/club support
- Update Organizations and Clubs views

**Phase 2 - Clarification Needed**:

- Sailing Vessel card implementation (after Q1 answered)
- Logo rendering optimization (after Q2 answered)
- Performance optimization if needed (after Q4 answered)

---

**END OF IMPLEMENTATION PLAN**
