# Issue: Expand Edit Your Profile Dialog with Accordion Fields and Organizations/Clubs/SVs Management

## 1. Problem Description

The current "Edit Your Profile" dialog (`client/src/views/account/profile.jsx`) uses simple text input fields for user information. We need to:

1. **Convert text inputs to read-only display fields with accordion behavior** - Similar to the "Edit User" dialog, convert `name`, `email`, `phone`, and `address` fields to read-only display fields that expand into detail fields (`name_`, `email_`, `phone_`, `address_`).

2. **Add clear separation between user info and account info** - Currently, user fields (name, email) and account fields (account_name) are intermingled. We need a clear visual separation.

3. **Add Organizations management** - Display and edit the list of organizations (`org_ids`) the user belongs to.

4. **Add Clubs management** - Display and edit the list of clubs (`club_ids`) the user belongs to.

5. **Add SVs (Boats) management** - Display and edit the list of SVs (`sv_ids`) the user owns. Note: An "SV" is a Boat + Owners + Handicapping Certs.

6. **Structure Organizations, Clubs, and SVs like Notifications** - Each should be a separate page/section with its own menu item, help card, and Card/Row/Form layout pattern.

## 2. Current State Analysis

### 2.1 Current Profile Page Structure

**File**: `client/src/views/account/profile.jsx`

- Uses simple `Form` component with `inputs` object
- Fields: `name` (text), `email` (email), `avatar` (file), `account_name` (text, owner only), `default_account_id` (select, multi-account only)
- No accordion behavior
- No separation between user and account fields
- No Organizations, Clubs, or SVs management

### 2.2 Edit User Dialog Reference (Completed)

**File**: `client/src/views/account/user-edit-form.jsx`

- Uses `CollapsibleSettingRow` component for accordion behavior
- Implements collapsible sections for `name/name_`, `email/email_`, `phone/phone_`, `address/address_`
- Uses `react-hook-form` with `Controller` for form management
- Real-time display field updates based on detail field changes
- Uses `CollapsibleSettingRow` component from `client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx`

### 2.3 Notifications Pattern Reference

**File**: `client/src/views/account/notifications.jsx`

- Uses `Card`, `Row`, `Form` layout pattern
- Uses `settingsMode={true}` for iOS-style settings layout
- Has its own route: `/account/notifications`
- Has its own menu item in account subnav
- Dynamically builds form inputs from settings structure
- Uses custom `handleSubmit` callback (no URL, callback-only mode)

### 2.4 User Schema

**File**: `server/model/mongo/user.mongo.js`

- `name` (String) - Display/assembled field
- `name_` (Object) - `{ prefix, first, middle, last, suffix }`
- `email` (String) - Primary login email
- `email_` (Object) - `{ primary, personal, work }`
- `phone` (String) - Display/assembled field
- `phone_` (Object) - `{ primary, cell, home, work }`
- `address` (String) - Display/assembled field
- `address_` (Object) - `{ company, c_o, street, unit, city, state, zip, country }`
- `org_ids` (Array) - Array of organization IDs
- `club_ids` (Array) - Array of club IDs
- `sv_ids` (Array) - Array of SV (boat) IDs
- `avatar` (String) - Profile picture URL
- `account` (Array) - Array of account objects
- `default_account_id` (String) - Default account ID

### 2.5 Related Models

**Organizations**: `server/model/mongo/org.mongo.js`

- Has `id`, `key`, `name`, `description`, etc.

**Clubs**: `server/model/mongo/club.mongo.js`

- Has `id`, `key`, `name`, `description`, etc.

**SVs**: `server/model/mongo/sv.mongo.js`

- Has `id`, `key`, `boat_key`, `boat_id`, `name`, `display`, `description`, `user_keys`, `user_ids`, `certs`, etc.

### 2.6 Current Routes and Navigation

**File**: `client/src/routes/account.js`

- `/account/profile` - Profile page
- `/account/notifications` - Notifications page

**File**: `client/src/components/layout/account/account.jsx`

- Subnav includes: Profile, Password, TFA, Billing, Notifications, API Keys, Users
- Uses `permission` field to control visibility

**File**: `client/src/views/account/index.jsx`

- Grid of cards linking to account pages
- Includes Profile and Notifications cards

## 3. Proposed Solution

### 3.1 Profile Page Refactoring

#### 3.1.1 Convert to Accordion Pattern

**File**: `client/src/views/account/profile.jsx`

**Changes**:

1. Replace `Form` component's `inputs` object with custom form using `react-hook-form`
2. Use `CollapsibleSettingRow` for `name`, `email`, `phone`, `address` fields
3. Keep `avatar` and account fields (`account_name`, `default_account_id`) as regular form fields
4. Add visual separation between user info section and account info section

**Structure**:

```jsx
<Animate>
    <Row width='lg'>
        <Card title={t('account.profile.subtitle')}>
            {/* USER INFO SECTION */}
            <div className="mb-6">
                <h3 className="text-lg font-semibold mb-4">{t('account.profile.sections.user_info')}</h3>

                {/* Name Collapsible */}
                <CollapsibleSettingRow ... />

                {/* Email Collapsible */}
                <CollapsibleSettingRow ... />

                {/* Phone Collapsible */}
                <CollapsibleSettingRow ... />

                {/* Address Collapsible */}
                <CollapsibleSettingRow ... />

                {/* Profile Picture (non-collapsible) */}
                <SettingRow>
                    <Input type="file" ... />
                </SettingRow>
            </div>

            {/* ACCOUNT INFO SECTION */}
            <div className="border-t pt-6">
                <h3 className="text-lg font-semibold mb-4">{t('account.profile.sections.account_info')}</h3>

                {/* Account Name (owner only) */}
                {user.data.permission === 'owner' && (
                    <SettingRow>
                        <Input type="text" ... />
                    </SettingRow>
                )}

                {/* Default Account (multi-account only) */}
                {user.data.accounts?.length > 1 && (
                    <SettingRow>
                        <Select ... />
                    </SettingRow>
                )}
            </div>

            {/* Save Button */}
            <Button type="submit" ... />
        </Card>
    </Row>
</Animate>
```

#### 3.1.2 Form Implementation Details

- Use `useForm` from `react-hook-form` (similar to `UserEditForm`)
- Parse `name_`, `email_`, `phone_`, `address_` from existing user data (same logic as `UserEditForm`)
- Handle form submission: PATCH `/api/user` with assembled data
- Update `authContext` on successful save (name, avatar, account_name)

#### 3.1.3 Display Field Styling

- **Label Position**: Label appears **above** the display field (not to the left), allowing display field to be full width
- **Display Field**: Full width read-only display fields with `bg-slate-200/75 dark:bg-black/30` background
- **Clickable to Expand**: Clicking on display field (or anywhere in the row) expands accordion
- **Chevron Icon**: Chevron icon (chevron-down/chevron-up) on right side
- **Email/Phone Click Behavior**: Clicking email or phone display fields opens the accordion (does NOT trigger `mailto:` or `tel:` links) - user is editing their own profile, not contacting themselves
- **Detail Fields**: Detail fields (`name_`, `email_`, `phone_`, `address_`) use exact same styling as "Edit User" dialog (horizontal layout with label on left)

### 3.2 Organizations Management Page

#### 3.2.1 New File Structure

**File**: `client/src/views/account/organizations.jsx` (CREATE)

**Pattern**: Follow `notifications.jsx` structure

**Features**:

- Display list of organizations user belongs to (from `user.org_ids`)
- Add/remove organizations
- Search/filter organizations
- Display organization details (name, description, etc.)

**UI Structure**:

```jsx
<Animate>
    <Row width='lg'>
        <Card title={t('account.organizations.subtitle')}>
            {/* Help Card */}
            <div className="mb-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                <p>{t('account.organizations.help.description')}</p>
            </div>

            {/* Organizations List */}
            <Form
                settingsMode={true}
                inputs={...}
                callback={handleSubmit}
            />
        </Card>
    </Row>
</Animate>
```

#### 3.2.2 API Integration

- **GET** `/api/user` - Get current user with `org_ids`
- **GET** `/api/org` - Get available organizations (for adding)
- **PATCH** `/api/user` - Update `org_ids` array

#### 3.2.3 Form Fields

- Display list of organizations user belongs to (from `user.org_ids`)
- **Add Button**: "+" button presents a dropdown/pull-down menu of available organizations from database
- User selects organization from dropdown to add it to their list
- Remove button/action for each organization in the list
- Same UI/UX pattern applies to Clubs and SVs pages

### 3.3 Clubs Management Page

#### 3.3.1 New File Structure

**File**: `client/src/views/account/clubs.jsx` (CREATE)

**Pattern**: Same as Organizations, but for clubs

**Features**:

- Display list of clubs user belongs to (from `user.club_ids`)
- Add/remove clubs
- Search/filter clubs
- Display club details

**UI Structure**: Same as Organizations

#### 3.3.2 API Integration

- **GET** `/api/user` - Get current user with `club_ids`
- **GET** `/api/club` - Get available clubs (for adding)
- **PATCH** `/api/user` - Update `club_ids` array

### 3.4 SVs (Boats) Management Page

#### 3.4.1 New File Structure

**File**: `client/src/views/account/svs.jsx` (CREATE)

**Pattern**: Same as Organizations/Clubs, but for SVs

**Features**:

- Display list of SVs user owns (from `user.sv_ids`)
- Add/remove SVs via "+" button with dropdown of available boats
- Display SV details (boat name, owners, handicapping certs)

**UI Structure**: Same as Organizations/Clubs

**Important Entity Relationship**:

- **BOAT**: The physical boat entity (defined once, persists over time)
- **SV (Sailing Vessel)**: A relationship entity linking USER (Owner) + BOAT + CERT(s)
- **USER claims ownership of a BOAT**: When user selects a boat, an SV is created referencing:
  - The USER (as Owner)
  - The BOAT (the physical boat)
- **SV requires CERT(s)**: Each SV needs handicapping certificates added to complete its definition
- **BOAT can have multiple Owners**: Multiple users can own the same boat (each creates their own SV)
- **BOAT can change ownership**: Over time, boat ownership changes, but the BOAT definition remains the same
- **CERT changes with ownership**: When ownership changes, the SV's CERT(s) would also change

**Workflow**:

1. User clicks "+" button
2. Dropdown shows available BOATs from database
3. User selects a BOAT
4. System creates an SV linking USER + BOAT
5. SV is added to `user.sv_ids` array
6. User can later add CERT(s) to the SV (future enhancement)

#### 3.4.2 API Integration

- **GET** `/api/user` - Get current user with `sv_ids`
- **GET** `/api/sv` - Get available SVs (for adding)
- **PATCH** `/api/user` - Update `sv_ids` array

### 3.5 Routes and Navigation Updates

#### 3.5.1 Routes

**File**: `client/src/routes/account.js` (MODIFY)

**Add**:

```javascript
{
    path: '/account/organizations',
    view: Organizations,
    layout: 'account',
    permission: 'user',
    title: 'account.index.title'
},
{
    path: '/account/clubs',
    view: Clubs,
    layout: 'account',
    permission: 'user',
    title: 'account.index.title'
},
{
    path: '/account/svs',
    view: SVs,
    layout: 'account',
    permission: 'user',
    title: 'account.index.title'
}
```

#### 3.5.2 Navigation

**File**: `client/src/components/layout/account/account.jsx` (MODIFY)

**Add to `subnav` array**:

```javascript
{
    label: t('account.nav.organizations'),
    link: '/account/organizations',
    icon: 'building',
    permission: 'user'
},
{
    label: t('account.nav.clubs'),
    link: '/account/clubs',
    icon: 'users',
    permission: 'user'
},
{
    label: t('account.nav.svs'),
    link: '/account/svs',
    icon: 'ship',
    permission: 'user'
}
```

#### 3.5.3 Account Index Cards

**File**: `client/src/views/account/index.jsx` (MODIFY)

**Add cards** (similar to Notifications card):

```jsx
<Card>
    <Icon name='building' size={iconSize}/>
    <h1>{t('account.organizations.title')}</h1>
    <span>{t('account.organizations.description')}</span>
    <Button
        size='xs'
        variant='outline'
        url='/account/organizations'
        text={t('account.organizations.button')}
    />
</Card>

<Card>
    <Icon name='users' size={iconSize}/>
    <h1>{t('account.clubs.title')}</h1>
    <span>{t('account.clubs.description')}</span>
    <Button
        size='xs'
        variant='outline'
        url='/account/clubs'
        text={t('account.clubs.button')}
    />
</Card>

<Card>
    <Icon name='ship' size={iconSize}/>
    <h1>{t('account.svs.title')}</h1>
    <span>{t('account.svs.description')}</span>
    <Button
        size='xs'
        variant='outline'
        url='/account/svs'
        text={t('account.svs.button')}
    />
</Card>
```

### 3.6 Backend Controller Updates

#### 3.6.1 User Controller

**File**: `server/controller/user.controller.js` (MODIFY)

**Update `exports.update` validation**:

- Already accepts `org_ids`, `club_ids`, `sv_ids` (verify)
- Ensure validation allows array of IDs
- Ensure update logic handles these arrays correctly

**Verify**:

- Joi validation schema includes these fields
- Update logic preserves existing arrays if not provided
- Update logic replaces arrays if provided

### 3.7 Locales Updates

#### 3.7.1 Profile Locales

**File**: `client/src/locales/en/account/en_profile.json` (MODIFY)

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

**Note**: Reuse existing locale keys from `en_users.json` for `name_`, `email_`, `phone_`, `address_` detail fields.

#### 3.7.2 Organizations Locales

**File**: `client/src/locales/en/account/en_organizations.json` (CREATE)

```json
{
  "title": "Organizations",
  "description": "Manage the organizations you belong to",
  "button": "Manage Organizations",
  "subtitle": "Your Organizations",
  "help": {
    "description": "Organizations represent groups or companies you are associated with. Add organizations to connect with other members."
  },
  "form": {
    "button": "Save Changes"
  },
  "nav": {
    "organizations": "Organizations"
  }
}
```

#### 3.7.3 Clubs Locales

**File**: `client/src/locales/en/account/en_clubs.json` (CREATE)

```json
{
  "title": "Clubs",
  "description": "Manage the clubs you belong to",
  "button": "Manage Clubs",
  "subtitle": "Your Clubs",
  "help": {
    "description": "Clubs represent sailing or boating organizations you are a member of. Add clubs to connect with other members."
  },
  "form": {
    "button": "Save Changes"
  },
  "nav": {
    "clubs": "Clubs"
  }
}
```

#### 3.7.4 SVs Locales

**File**: `client/src/locales/en/account/en_svs.json` (CREATE)

```json
{
  "title": "SVs (Boats)",
  "description": "Manage the boats you own",
  "button": "Manage Boats",
  "subtitle": "Your Boats",
  "help": {
    "description": "SVs (Sailing Vessels) represent boats you own, including boat details, owners, and handicapping certificates."
  },
  "form": {
    "button": "Save Changes"
  },
  "nav": {
    "svs": "SVs (Boats)"
  }
}
```

#### 3.7.5 Navigation Locales

**File**: `client/src/locales/en/en_nav.json` (MODIFY)

**Add** (if not exists):

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

## 4. Implementation Plan

### Step 1: Refactor Profile Page

**File**: `client/src/views/account/profile.jsx`

**Actions**:

1. Import `useForm`, `Controller` from `react-hook-form`
2. Import `CollapsibleSettingRow`, `SettingRow` from components
3. Import utility functions: `parseName`, `parseAddress`, `formatPhone`
4. Replace `Form` component with custom form using `react-hook-form`
5. Implement `CollapsibleSettingRow` for `name`, `email`, `phone`, `address`
6. Add visual separation between user info and account info sections
7. Keep `avatar`, `account_name`, `default_account_id` as regular fields
8. Implement form submission handler (PATCH `/api/user`)
9. Update `authContext` on successful save

**Dependencies**: None (all components exist)

### Step 2: Create Organizations Page

**File**: `client/src/views/account/organizations.jsx` (CREATE)

**Actions**:

1. Create new file following `notifications.jsx` pattern
2. Use `Card`, `Row`, `Form` layout
3. Add help card with description
4. Implement form to display/edit `org_ids`
5. Add search/filter functionality for available organizations
6. Implement add/remove organizations logic
7. Use `settingsMode={true}` for iOS-style layout
8. Implement custom `handleSubmit` callback (PATCH `/api/user`)

**Dependencies**:

- Verify `/api/org` endpoint exists for fetching available organizations
- Verify user controller accepts `org_ids` in update

### Step 3: Create Clubs Page

**File**: `client/src/views/account/clubs.jsx` (CREATE)

**Actions**: Same as Organizations, but for clubs

**Dependencies**:

- Verify `/api/club` endpoint exists
- Verify user controller accepts `club_ids` in update

### Step 4: Create SVs Page

**File**: `client/src/views/account/svs.jsx` (CREATE)

**Actions**: Same as Organizations/Clubs, but for SVs

**Dependencies**:

- Verify `/api/sv` endpoint exists
- Verify user controller accepts `sv_ids` in update

### Step 5: Update Routes

**File**: `client/src/routes/account.js` (MODIFY)

**Actions**:

1. Import new components: `Organizations`, `Clubs`, `SVs`
2. Add three new route objects

### Step 6: Update Navigation

**File**: `client/src/components/layout/account/account.jsx` (MODIFY)

**Actions**:

1. Add three new items to `subnav` array

### Step 7: Update Account Index

**File**: `client/src/views/account/index.jsx` (MODIFY)

**Actions**:

1. Add three new `Card` components for Organizations, Clubs, SVs

### Step 8: Update Locales

**Files**: Multiple locale files (MODIFY/CREATE)

**Actions**:

1. Update `en_profile.json` with section labels
2. Create `en_organizations.json`
3. Create `en_clubs.json`
4. Create `en_svs.json`
5. Update `en_nav.json` with navigation labels
6. Add Spanish translations (if `es_` files exist)

### Step 9: Verify Backend Support

**File**: `server/controller/user.controller.js` (VERIFY)

**Actions**:

1. Verify Joi validation accepts `org_ids`, `club_ids`, `sv_ids` arrays
2. Verify update logic handles these arrays correctly
3. Add validation if missing

### Step 10: Test Implementation

**Actions**:

1. Test Profile page accordion behavior
2. Test Organizations add/remove
3. Test Clubs add/remove
4. Test SVs add/remove
5. Test navigation between pages
6. Test form submissions and data persistence
7. Test error handling

## 5. Files to Modify/Create

### Frontend - Profile Page:

- `client/src/views/account/profile.jsx` (MODIFY - major refactor)

### Frontend - New Pages:

- `client/src/views/account/organizations.jsx` (CREATE)
- `client/src/views/account/clubs.jsx` (CREATE)
- `client/src/views/account/svs.jsx` (CREATE)

### Frontend - Routes:

- `client/src/routes/account.js` (MODIFY)

### Frontend - Navigation:

- `client/src/components/layout/account/account.jsx` (MODIFY)
- `client/src/views/account/index.jsx` (MODIFY)

### Frontend - Locales:

- `client/src/locales/en/account/en_profile.json` (MODIFY)
- `client/src/locales/en/account/en_organizations.json` (CREATE)
- `client/src/locales/en/account/en_clubs.json` (CREATE)
- `client/src/locales/en/account/en_svs.json` (CREATE)
- `client/src/locales/en/en_nav.json` (MODIFY)
- `client/src/locales/es/account/es_profile.json` (MODIFY - if exists)
- `client/src/locales/es/account/es_organizations.json` (CREATE - if es exists)
- `client/src/locales/es/account/es_clubs.json` (CREATE - if es exists)
- `client/src/locales/es/account/es_svs.json` (CREATE - if es exists)

### Backend - Verification:

- `server/controller/user.controller.js` (VERIFY - may need MODIFY)

## 6. Test Cases

### 6.1 Profile Page Tests

**Test Case 1: Accordion Expansion**

- **Given**: User is on Profile page
- **When**: User clicks on Name display field
- **Then**: Name accordion expands showing prefix, first, middle, last, suffix fields
- **And**: Other accordions (email, phone, address) remain closed

**Test Case 2: Real-time Display Updates**

- **Given**: Name accordion is expanded
- **When**: User types in First Name field
- **Then**: Display field updates in real-time showing assembled name

**Test Case 3: Form Submission**

- **Given**: User has edited name, email, phone, address fields
- **When**: User clicks Save button
- **Then**: Form submits PATCH `/api/user` with assembled data
- **And**: `authContext` updates with new name, avatar, account_name
- **And**: Success notification appears

**Test Case 4: Visual Separation**

- **Given**: User is on Profile page
- **When**: Page loads
- **Then**: User info section (name, email, phone, address, avatar) appears at top
- **And**: Account info section (account_name, default_account_id) appears below with visual separator

**Test Case 5: Read-only Display Fields**

- **Given**: User is on Profile page
- **When**: Page loads
- **Then**: Name, email, phone, address fields appear as read-only display fields
- **And**: Display fields have accordion chevron icon
- **And**: Email display is clickable `mailto:` link
- **And**: Phone display is clickable `tel:` link

### 6.2 Organizations Page Tests

**Test Case 1: Display Organizations**

- **Given**: User belongs to organizations (has `org_ids`)
- **When**: User navigates to Organizations page
- **Then**: List of organizations displays
- **And**: Each organization shows name and description

**Test Case 2: Add Organization**

- **Given**: User is on Organizations page
- **When**: User searches for organization and clicks Add
- **Then**: Organization is added to `org_ids` array
- **And**: Form submits PATCH `/api/user` with updated `org_ids`
- **And**: Organization appears in list

**Test Case 3: Remove Organization**

- **Given**: User belongs to organizations
- **When**: User clicks Remove on an organization
- **Then**: Organization is removed from `org_ids` array
- **And**: Form submits PATCH `/api/user` with updated `org_ids`
- **And**: Organization disappears from list

### 6.3 Clubs Page Tests

**Test Cases**: Same as Organizations, but for clubs (`club_ids`)

### 6.4 SVs Page Tests

**Test Cases**: Same as Organizations, but for SVs (`sv_ids`)

### 6.5 Navigation Tests

**Test Case 1: Navigation Menu**

- **Given**: User is on any account page
- **When**: User views side navigation
- **Then**: Organizations, Clubs, SVs menu items appear
- **And**: Clicking menu items navigates to respective pages

**Test Case 2: Account Index Cards**

- **Given**: User is on Account index page
- **When**: Page loads
- **Then**: Organizations, Clubs, SVs cards appear
- **And**: Clicking cards navigates to respective pages

## 7. Questions & Assumptions

### Questions:

1. **API Endpoints**: Do `/api/org`, `/api/club`, `/api/sv` endpoints exist for fetching available organizations/clubs/SVs? If not, what endpoints should be used?

2. **Organization/Club/SV Selection UI**: What UI pattern should be used for selecting organizations/clubs/SVs?

   - Multi-select dropdown?
   - Checkbox list?
   - Search + Add button?
   - Table with add/remove actions?

3. **SV Display**: What information should be displayed for each SV in the list?

   - Boat name only?
   - Boat name + owners?
   - Boat name + owners + handicapping certs?

4. **Permissions**: Should Organizations, Clubs, SVs pages be visible to all users, or only specific permission levels?

5. **Help Cards**: What content should be in the help cards for Organizations, Clubs, SVs pages?

6. **Account Info Section**: Should account info section be collapsible/expandable, or always visible?

7. **Profile Picture**: Should profile picture field remain as file input, or be converted to a different pattern?

8. **Default Account Selection**: Should default account selection remain as select dropdown, or use a different pattern?

### Assumptions:

1. **API Endpoints**: Assuming `/api/org`, `/api/club`, `/api/sv` endpoints exist (or will be created) for fetching available items.

2. **User Controller**: Assuming `user.controller.js` already accepts `org_ids`, `club_ids`, `sv_ids` in update validation (needs verification).

3. **UI Pattern**: Assuming Organizations/Clubs/SVs pages use similar UI pattern to Notifications (search + checkbox list or multi-select).

4. **Permissions**: Assuming all users can manage their own organizations/clubs/SVs (permission: 'user').

5. **Visual Separation**: Assuming user info and account info sections are separated by a border/divider, not collapsible sections.

6. **Profile Picture**: Assuming profile picture remains as file input field (not converted to accordion).

7. **Locale Keys**: Assuming existing locale keys from `en_users.json` can be reused for profile page detail fields (`name_`, `email_`, `phone_`, `address_`).

8. **Backend Sync**: Assuming backend controller already handles assembly of `name`, `email`, `phone`, `address` from `_` fields (same as Edit User).

## 8. Confidence Score

**75%**

### High Confidence Areas:

- ✅ Profile page accordion implementation (pattern exists in UserEditForm)
- ✅ CollapsibleSettingRow component usage (component exists and is tested)
- ✅ Routes and navigation structure (pattern exists)
- ✅ Locales structure (pattern exists)

### Medium Confidence Areas:

- ⚠️ Organizations/Clubs/SVs page implementation (needs API endpoint verification)
- ⚠️ UI pattern for selecting organizations/clubs/SVs (needs clarification)
- ⚠️ Backend controller validation (needs verification)

### Low Confidence Areas:

- ❓ API endpoints for fetching available organizations/clubs/SVs (needs verification)
- ❓ Exact UI pattern for add/remove organizations/clubs/SVs (needs clarification)
- ❓ SV display format (needs clarification)

## 9. Next Steps

1. **Verify API Endpoints**: Check if `/api/org`, `/api/club`, `/api/sv` endpoints exist and what they return.

2. **Clarify UI Patterns**: Get clarification on:

   - How users should select/add organizations/clubs/SVs
   - What information to display for each item
   - Help card content

3. **Verify Backend**: Check `user.controller.js` to ensure it accepts `org_ids`, `club_ids`, `sv_ids` in update validation.

4. **Review Design**: Review this design document with stakeholders to confirm approach.

5. **Update Confidence**: Once questions are answered, update confidence score and proceed with implementation.
