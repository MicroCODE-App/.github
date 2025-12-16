# Implementation Plan: Theme Settings Page

## Executive Summary

This document outlines the implementation plan for adding a "Theme" settings page to the user account settings. The new page will allow users to control theme-related preferences (dark mode, base color, language) and sound settings, positioned between "Billing" and "Notifications" in the navigation sidebar.

## Current State Analysis

### Existing Settings Structure

The application already has a hierarchical settings structure defined in `server/api/spec.yaml`:

```yaml
settings:
  theme:
    sight:
      darkMode: boolean
      baseColor: string (e.g., "purple", "blue")
      language: string (e.g., "en", "es")
    sound:
      muteAll: boolean
      useAssist: boolean
      useEffects: boolean
```

### Current Navigation Structure

**File**: `client/src/components/layout/account/account.jsx`

Current navigation order:

1. Profile
2. Password
3. 2FA
4. Billing ← **Insert Theme here**
5. Notifications ← **After Theme**
6. Organizations
7. Clubs
8. Sailing Vessels
9. API Keys
10. Users

### Existing Theme Usage

- Theme settings are already read in `client/src/components/user/user.jsx` and `client/src/app/app.jsx`
- Dark mode is extracted from `settings.theme.sight.darkMode`
- Theme is cached in localStorage with key `user_theme`

### Reference Implementation

The `Notifications` view (`client/src/views/account/notifications.jsx`) provides an excellent reference:

- Uses `settingsMode={true}` with Form component
- Reads from `authContext.user.settings`
- Saves via `/api/user/settings/all` endpoint
- Updates `authContext` after save
- Uses section headers for organization

## Implementation Requirements

### 1. Navigation Sidebar Update

**File**: `client/src/components/layout/account/account.jsx`

**Changes**:

- Add new navigation item for "Theme" between "Billing" (line 80-84) and "Notifications" (line 86-90)
- Use icon: `'palette'` or `'paintbrush'` (check available icons)
- Permission: `'user'` (same as Profile, Password, etc.)
- Link: `/account/theme`

**Position**: Insert at line 85 (after Billing, before Notifications)

### 2. Route Configuration

**File**: `client/src/routes/account.js`

**Changes**:

- Import new Theme component: `import { Theme } from 'views/account/theme';`
- Add route configuration:
  ```javascript
  {
      path: '/account/theme',
      view: Theme,
      layout: 'account',
      permission: 'user',
      title: 'account.index.title'
  }
  ```
- Position: After Billing route (line 50), before Notifications route (line 66)

### 3. New Theme View Component

**File**: `client/src/views/account/theme.jsx` (NEW FILE)

**Structure**:

- Similar to `notifications.jsx` but focused on theme settings
- Read settings from `authContext.user.settings.theme`
- Build form inputs for:
  - **Sight Control Section**:
    - Dark Mode (switch) - `theme.sight.darkMode`
    - Preferred Background/Base Color (select) - `theme.sight.baseColor`
    - Preferred Language (select) - `theme.sight.language`
  - **Sound Control Section**:
    - Mute All Sound & Voice (switch) - `theme.sound.muteAll`
    - Use Sound Effects (switch) - `theme.sound.useEffects`
    - Use Voice Assistance (switch) - `theme.sound.useAssist`

**Form Configuration**:

- Use `settingsMode={true}` for iOS-style horizontal layout
- Use `SettingRow` wrapper (handled automatically by Form with `settingsMode`)
- Switch inputs use `type: 'switch'` with `labelWidth: 95`
- Select inputs use `type: 'select'` with appropriate options
- Section headers use `type: 'section'`

**Save Logic**:

- Use `/api/user/settings/all` endpoint
- Preserve all other settings (messages, support, etc.)
- Update `authContext` after successful save
- Show success/error notifications via `ViewContext`

### 4. Translation Files

**Files to Create/Update**:

#### `client/src/locales/en/account/en_nav.json`

- Add: `"theme": "Theme"`

#### `client/src/locales/en/account/en_theme.json` (NEW FILE)

**Structure**:

```json
{
  "title": "Theme",
  "subtitle": "Theme Settings",
  "description": "Customize your app appearance and sound preferences",
  "sections": {
    "sight": {
      "label": "Sight Control",
      "description": "Visual appearance and display settings"
    },
    "sound": {
      "label": "Sound Control",
      "description": "Audio and sound preferences"
    }
  },
  "form": {
    "options": {
      "darkMode": "Use Dark Mode",
      "darkMode_desc": "Enable dark mode for a darker interface",
      "baseColor": "Preferred Background",
      "baseColor_desc": "Choose your preferred base color theme",
      "language": "Preferred Language",
      "language_desc": "Select your preferred interface language",
      "muteAll": "Mute All Sound & Voice",
      "muteAll_desc": "Disable all audio output",
      "useEffects": "Use Sound Effects",
      "useEffects_desc": "Enable sound effects",
      "useAssist": "Use Voice Assistance",
      "useAssist_desc": "Enable voice assistance features"
    },
    "button": "Save Theme Settings"
  }
}
```

### 5. Form Input Options

**Base Color Options** (for select dropdown):

- Black
- Purple (default)
- Blue

**Language Options** (for select dropdown):

- **Dynamic from DB**: Fetch from `/api/locale` endpoint (from `locales` collection)
- **Filter**: Only show `en` and `es` (per requirement)
- **Format**: `{value: 'en', label: 'English'}` (exact format TBD - see Q1-Q3 in validation review)

**Default Values**:

- `darkMode`: `true` (or read from current settings, fallback from `config/default.json`)
- `baseColor`: `"purple"` (or read from current settings, fallback from `config/default.json`)
- `language`: `"en"` (or read from current settings, fallback from `config/default.json`)
- `muteAll`: `true` (or read from current settings, fallback from `config/default.json`)
- `useEffects`: `false` (or read from current settings, fallback from `config/default.json`)
- `useAssist`: `false` (or read from current settings, fallback from `config/default.json`)

### 6. Account Index Page Update

**File**: `client/src/views/account/index.jsx`

**Status**: **NOT REQUIRED** - Per user requirement, Theme is per User not Account, so no card needed on account index page.

## Technical Specifications

### Component Architecture

```
Theme View Component
├── Reads from: authContext.user.settings.theme
├── Form Component (settingsMode=true)
│   ├── Section Header: "Sight Control"
│   ├── SettingRow: Dark Mode (Switch)
│   ├── SettingRow: Preferred Background (Select)
│   ├── SettingRow: Preferred Language (Select)
│   ├── Section Header: "Sound Control"
│   ├── SettingRow: Mute All (Switch)
│   ├── SettingRow: Sound Effects (Switch)
│   └── SettingRow: Voice Assistance (Switch)
└── Saves to: /api/user/settings/all
```

### Visual Layout Diagram

```
┌──────────────────────────────────────────────────────────┐
│  Account Layout                                          │
│                                                          │
│  ┌──────────────┐  ┌─────────────────────────────────┐   │
│  │ Sidebar Nav  │  │  Main Content Area              │   │
│  │              │  │                                 │   │
│  │ Profile      │  │  ┌────────────────────────────┐ │   │
│  │ Password     │  │  │ Theme Settings             │ │   │
│  │ 2FA          │  │  │                            │ │   │
│  │ Billing      │  │  │ Sight Control              │ │   │
│  │ Theme ◄──────┼──┼──│ Visual appearance...       │ │   │
│  │ Notifications│  │  │                            │ │   │
│  │ Organizations│  │  │ Use Dark Mode        [●──] │ │   │
│  │ Clubs        │  │  │ Preferred Background  [▼]  │ │   │
│  │ SVs          │  │  │ Preferred Language    [▼]  │ │   │
│  │ API Keys     │  │  │                            │ │   │
│  │ Users        │  │  │ Sound Control              │ │   │
│  │              │  │  │ Audio preferences...       │ │   │
│  │              │  │  │                            │ │   │
│  │              │  │  │ Mute All Sound      [●──]  │ │   │
│  │              │  │  │ Use Sound Effects   [●──]  │ │   │
│  │              │  │  │ Use Voice Assist   [──○]   │ │   │
│  │              │  │  │                            │ │   │
│  │              │  │  │ [Save Theme Settings]      │ │   │
│  │              │  │  └────────────────────────────┘ │   │
│  └──────────────┘  └─────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘

Legend:
  [●──] = Switch ON (green)
  [──○] = Switch OFF (grey)
  [▼]   = Select dropdown
```

### Data Flow

1. **Load**: Read `authContext.user.settings.theme` on component mount
2. **Display**: Map settings to form inputs with defaults
3. **Edit**: User modifies form inputs
4. **Save**: On submit, merge updated theme settings with existing settings
5. **Update**: Call `/api/user/settings/all` with complete settings object
6. **Sync**: Update `authContext` with response data
7. **Notify**: Show success/error notification

### API Contract

**Endpoint**: `PUT /api/user/settings/all`

**Request Body**:

```json
{
  "settings": {
    "theme": {
      "sight": {
        "darkMode": true,
        "baseColor": "purple",
        "language": "en"
      },
      "sound": {
        "muteAll": false,
        "useEffects": true,
        "useAssist": false
      }
    },
    "messages": { ... },
    "support": { ... }
  }
}
```

**Response**: Returns updated user object with settings

### Form Input Mapping

| Form Field Key | Settings Path            | Type    | Component | Default Value |
| -------------- | ------------------------ | ------- | --------- | ------------- |
| `darkMode`     | `theme.sight.darkMode`   | boolean | Switch    | `true`        |
| `baseColor`    | `theme.sight.baseColor`  | string  | Select    | `"purple"`    |
| `language`     | `theme.sight.language`   | string  | Select    | `"en"`        |
| `muteAll`      | `theme.sound.muteAll`    | boolean | Switch    | `true`        |
| `useEffects`   | `theme.sound.useEffects` | boolean | Switch    | `false`       |
| `useAssist`    | `theme.sound.useAssist`  | boolean | Switch    | `false`       |

### Settings Object Structure

```javascript
// Current user settings structure
user.settings = {
  theme: {
    sight: {
      darkMode: boolean,      // false = light mode, true = dark mode
      baseColor: string,       // "purple", "blue", "gray", etc.
      language: string         // "en", "es", "de", "fr", etc.
    },
    sound: {
      muteAll: boolean,        // Master mute switch
      useEffects: boolean,     // Sound effects toggle
      useAssist: boolean       // Voice assistance toggle
    }
  },
  messages: { ... },           // Preserved during save
  support: { ... }             // Preserved during save
}
```

## Files to Modify

### Existing Files (5 files)

1. `client/src/components/layout/account/account.jsx`

   - Add navigation item for Theme

2. `client/src/routes/account.js`

   - Import Theme component
   - Add Theme route

3. `client/src/locales/en/account/en_nav.json`

   - Add "theme" translation key

4. `client/src/views/account/index.jsx` (Optional)

   - Add Theme card to grid

5. `client/src/components/lib.jsx` (if needed)
   - Export Theme component if using barrel exports

### New Files (2 files)

1. `client/src/views/account/theme.jsx`

   - Main Theme settings view component

2. `client/src/locales/en/account/en_theme.json`
   - Translation strings for Theme page

## Implementation Steps

### Phase 1: Setup (Foundation)

1. Create translation file `en_theme.json`
2. Add "theme" to `en_nav.json`
3. Create `theme.jsx` component skeleton

### Phase 2: Navigation & Routing

4. Add Theme navigation item to sidebar
5. Add Theme route to routes configuration
6. Verify navigation works

### Phase 3: Form Implementation

7. Implement Sight Control section (Dark Mode, Base Color, Language)
8. Implement Sound Control section (Mute All, Sound Effects, Voice Assistance)
9. Configure form inputs with proper types and options

### Phase 4: Data Integration

10. Implement settings read logic from `authContext`
11. Implement settings save logic with API call
12. Implement `authContext` update after save
13. Add error handling and notifications

### Phase 5: Testing & Refinement

14. Test form submission
15. Verify settings persist correctly
16. Test default values and fallbacks
17. Verify UI matches design (iOS-style horizontal layout)
18. Test with different permission levels

## Design Considerations

### UI/UX Alignment

Based on Image 1 and Image 2:

1. **Layout**: iOS-style horizontal settings rows (already implemented via `settingsMode`)
2. **Sections**: Use section headers to group related settings
3. **Switches**: Green when on, grey when off (iOS-style)
4. **Selects**: Dropdown with chevron icon, right-aligned
5. **Spacing**: Consistent padding and borders between rows

### Accessibility

- All form inputs should have proper labels
- Descriptions provide context for each setting
- Error messages displayed inline
- Keyboard navigation support (handled by Form component)

### Performance

- Settings read once on mount
- Form updates local state only
- Single API call on submit (not per-field)
- `authContext` update triggers re-render only where needed

## Questions for Clarification

Before proceeding with implementation, please clarify:

1. **Icon Selection**: What icon should be used for Theme in the navigation sidebar?

   - **Recommendation**: `'palette'` (Lucide React icon - most common for theme/color settings)
   - Alternatives: `'paintbrush'`, `'brush'`, `'sparkles'`
   - Icons are from Lucide React library (https://lucide.dev/icons/)

2. **Base Color Options**: What are the exact base color values to support? Should these match existing theme colors in the app, or are there specific brand colors?

3. **Language Options**: What languages should be available in the language selector? Should this match the available locale files in `client/src/locales/`?

4. **Default Values**: What should the default values be for new users who haven't set theme preferences yet?

5. **Real-time Updates**: Should changes to Dark Mode apply immediately (like in `user.jsx`), or only after saving?

6. **Sound Settings**: Are the sound settings actually functional in the app, or are they placeholders for future functionality?

7. **Account Index Page**: Should Theme be added as a card on the account index page (`/account`), or only accessible via sidebar navigation?

8. **Permission Level**: Confirm that Theme should be available to all users (`permission: 'user'`), not just owners or admins?

9. **Section Order**: Should "Sight Control" come before "Sound Control", or vice versa?

10. **Translation Files**: Should we create translation files for other locales (es, de, fr, etc.) now, or only English for initial implementation?

## Risk Assessment

### Low Risk

- Adding navigation item (well-established pattern)
- Creating new view component (follows existing pattern)
- Translation file creation (standard process)

### Medium Risk

- Form input mapping (ensure correct settings path)
- Settings merge logic (must preserve other settings)
- Default value handling (edge cases for new users)

### Mitigation Strategies

- Follow existing `notifications.jsx` pattern closely
- Test with existing user data
- Test with new user (no settings)
- Verify settings merge doesn't overwrite other sections

## Success Criteria

1. ✅ Theme navigation item appears between Billing and Notifications
2. ✅ Theme page loads and displays current settings
3. ✅ All form inputs render correctly in iOS-style horizontal layout
4. ✅ Settings save successfully via API
5. ✅ Settings persist after page reload
6. ✅ Other settings (notifications, etc.) are preserved
7. ✅ Success/error notifications display correctly
8. ✅ UI matches design reference (Image 1 & Image 2)
9. ✅ Translations work correctly
10. ✅ Component follows existing code patterns

## Dependencies

- Existing Form component with `settingsMode` support
- Existing SettingRow component
- Existing Switch and Select input components
- Existing `/api/user/settings/all` endpoint
- Existing AuthContext for user settings
- Existing ViewContext for notifications

## Timeline Estimate

- **Phase 1**: 30 minutes
- **Phase 2**: 15 minutes
- **Phase 3**: 1-2 hours
- **Phase 4**: 1 hour
- **Phase 5**: 1 hour

**Total**: ~4-5 hours

---

## Appendix: Code Structure Preview

### Theme Component Structure (Preview)

```javascript
export function Theme({ t })
{
    const authContext = useContext(AuthContext);
    const viewContext = useContext(ViewContext);
    const [loading, setLoading] = useState(false);

    // Read theme settings from authContext
    const themeSettings = authContext.user?.settings?.theme || {};
    const sightSettings = themeSettings.sight || {};
    const soundSettings = themeSettings.sound || {};

    // Build form inputs
    const inputs = {
        // Section headers
        _sight_header: { type: 'section', ... },
        _sound_header: { type: 'section', ... },

        // Sight controls
        darkMode: { type: 'switch', ... },
        baseColor: { type: 'select', options: [...], ... },
        language: { type: 'select', options: [...], ... },

        // Sound controls
        muteAll: { type: 'switch', ... },
        useEffects: { type: 'switch', ... },
        useAssist: { type: 'switch', ... }
    };

    // Handle form submission
    const handleSubmit = async (res, data) => {
        // Merge theme settings with existing settings
        // Call API
        // Update authContext
        // Show notification
    };

    return (
        <Animate>
            <Row width='lg'>
                <Card title={t('account.theme.subtitle')}>
                    <Form
                        inputs={inputs}
                        settingsMode={true}
                        buttonText={t('account.theme.form.button')}
                        callback={handleSubmit}
                    />
                </Card>
            </Row>
        </Animate>
    );
}
```

---

## Summary

This implementation plan provides a comprehensive roadmap for adding a Theme settings page to the user account section. The plan follows established patterns in the codebase (particularly the Notifications view) and integrates seamlessly with the existing settings infrastructure.

### Key Highlights

- **Minimal Changes**: Only 5 existing files need modification, 2 new files need creation
- **Pattern Consistency**: Follows the exact same pattern as the Notifications view
- **No Breaking Changes**: All changes are additive, preserving existing functionality
- **Well-Documented**: Clear structure, questions, and specifications provided

### Next Steps

1. **Review this plan** and answer the clarification questions
2. **Approve the approach** or request modifications
3. **Provide answers** to the 10 clarification questions
4. **Wait for explicit "implement" command** before making any code changes

### Critical Dependencies

- All dependencies already exist in the codebase
- No new packages or libraries required
- Uses existing Form, SettingRow, Switch, and Select components
- Uses existing `/api/user/settings/all` endpoint
- Uses existing AuthContext and ViewContext

---

**Document Version**: 1.0
**Created**: 2024
**Status**: Ready for Review
**Next Action**: Awaiting clarification answers and explicit implementation command
