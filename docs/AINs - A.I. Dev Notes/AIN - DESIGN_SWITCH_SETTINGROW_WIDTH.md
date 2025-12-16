# Design: Switch Component Full-Width Label Support in SettingRow

## Problem Statement

The `SettingRow` component was modified to support User Edit form requirements where display fields needed specific width constraints (30% label, 70% control). This change introduced a hardcoded `maxWidth: '40%'` constraint on the label area, which adversely affects Switch components throughout the application.

**Current Issue:**

- Switch settings (e.g., Notification Settings) have labels/descriptions constrained to ~40% width
- This causes text wrapping and poor UX for Switch components that previously had almost full width
- The constraint was necessary for text display/input fields but should not apply to Switch components

**Requirements:**

1. Switch components should have almost full width for labels/descriptions (restore original behavior)
2. Text display/input fields should maintain the 30% label width limit (preserve current behavior)
3. Solution must be backward compatible
4. No breaking changes to existing functionality

## Current Architecture

### Components Involved

1. **`SettingRow`** (`client/src/components/form/setting-row/setting-row.jsx`)

   - Horizontal settings row component with iOS-style layout
   - Currently has hardcoded `maxWidth: '40%'` on label area
   - Has `controlWidth` prop for explicit control area sizing
   - Used by both Form component and CollapsibleSettingRow

2. **`Form`** (`client/src/components/form/form.jsx`)

   - Dynamic form component that renders inputs
   - Uses `SettingRow` when `settingsMode={true}`
   - Has access to input type information via `inputs[name].type`

3. **`CollapsibleSettingRow`** (`client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx`)

   - Uses `SettingRow` internally
   - Currently passes `controlWidth='70%'` for display fields

4. **`Switch`** (`client/src/components/form/input/switch/switch.jsx`)
   - Toggle switch component
   - Used in notifications, TFA, and other settings pages

### Current Implementation Details

**SettingRow Component:**

```jsx
// Label area - CURRENTLY HARDCODED TO 40%
<div className='flex-1 pr-4 min-w-0' style={{
    maxWidth: '40%'
}}>
    {/* Label and description */}
</div>

// Control area - USES controlWidth PROP OR DEFAULTS TO 60%
<div className='flex-shrink-0 min-w-0 overflow-hidden' style={{
    width: controlWidth || '60%',
    maxWidth: controlWidth || '60%'
}}>
    { children }
</div>
```

**Form Component Usage:**

```jsx
// When settingsMode is true, wraps inputs in SettingRow
<SettingRow
    label={ label }
    description={ description }
    error={ errors[name]?.message }
    required={ required }
>
    <Input.component ... />
</SettingRow>
```

**Switch Usage Pattern:**

- Switch components are rendered via Form component with `settingsMode={true}`
- Input type is `'switch'` (from `inputs[name].type`)
- Switch components typically have longer labels and descriptions that need more space

## Proposed Solution

### High-Level Approach

Add a new numeric prop `labelWidth` to `SettingRow` that:

1. Accepts a number (0-100) representing the percentage width for the label area
2. Defaults to `40` (maintains current behavior when not provided)
3. Form component detects Switch input type and passes `labelWidth={95}` to SettingRow
4. CollapsibleSettingRow continues to use `controlWidth` for its specific needs
5. Provides flexibility for future use cases with any percentage value

### Design Decisions

1. **New Prop: `labelWidth`**

   - Numeric prop (0-100, representing percentage)
   - Default: `40` (maintains current `maxWidth: '40%'` behavior)
   - When provided, sets `maxWidth: '{labelWidth}%'` on label area
   - Examples: `30` (narrow labels), `40` (default), `95` (full-width for Switch)
   - Provides fine-grained control for future flexibility

2. **Input Type Detection**

   - Form component already has access to `inputs[name].type`
   - Maps input types to `labelWidth` values:
     - `switch`: `95` (almost full width)
     - `radio`, `checkbox`: `90` (extensible for future)
     - Other types: `undefined` (defaults to 40)
   - Extensible for any future input types

3. **Control Width Logic**

   - When `labelWidth` provided:
     - If `labelWidth >= 90`: Control area uses `width: 'auto'` with `minWidth: '44px'` (for Switch)
     - Otherwise: Control width calculated as `100 - labelWidth`
   - When `controlWidth` prop provided: Takes precedence over calculated width
   - When neither provided: Defaults to 60% control width

4. **Backward Compatibility**
   - Default value (40) preserves existing behavior
   - Existing code continues to work without changes
   - Only affects components that explicitly set `labelWidth` prop

## Detailed Implementation Plan

### Phase 1: Update SettingRow Component

**File:** `client/src/components/form/setting-row/setting-row.jsx`

**Changes:**

1. Add `fullWidthLabel` prop to component signature and JSDoc
2. Conditionally apply `maxWidth` style based on `fullWidthLabel` prop
3. Adjust control area width logic when `fullWidthLabel={true}`

**Code Changes:**

```jsx
/**
 * @param {number} params.labelWidth Optional label width as percentage (0-100).
 *                                   Default: 40. When provided, sets maxWidth on label area.
 *                                   Examples: 30 (narrow), 40 (default), 95 (full-width for Switch).
 */
const SettingRow = forwardRef(({
    label,
    description,
    children,
    error,
    required,
    className,
    layout = 'horizontal',
    controlWidth,
    labelWidth, // NEW PROP (number, optional)
    ...props
}, ref) => {
    if (layout === 'horizontal') {
        // Calculate label area maxWidth
        const labelMaxWidth = labelWidth !== undefined
            ? `${labelWidth}%`
            : '40%'; // Default maintains current behavior

        // Calculate control area width
        let controlAreaWidth;
        let controlAreaMaxWidth;

        if (controlWidth) {
            // Explicit controlWidth takes precedence (for CollapsibleSettingRow)
            controlAreaWidth = controlWidth;
            controlAreaMaxWidth = controlWidth;
        } else if (labelWidth !== undefined) {
            // Calculate from labelWidth
            if (labelWidth >= 90) {
                // For Switch components (labelWidth >= 90), use auto-sizing
                controlAreaWidth = 'auto';
                controlAreaMaxWidth = 'none';
            } else {
                // Calculate remaining width
                const remainingWidth = 100 - labelWidth;
                controlAreaWidth = `${remainingWidth}%`;
                controlAreaMaxWidth = `${remainingWidth}%`;
            }
        } else {
            // Default behavior
            controlAreaWidth = '60%';
            controlAreaMaxWidth = '60%';
        }

        return (
            <div ...>
                {/* Label area - CONDITIONAL MAXWIDTH */}
                <div className='flex-1 pr-4 min-w-0' style={{
                    maxWidth: labelMaxWidth
                }}>
                    {/* Label and description */}
                </div>

                {/* Control area - CONDITIONAL WIDTH */}
                <div className='flex-shrink-0 min-w-0 overflow-hidden' style={{
                    width: controlAreaWidth,
                    maxWidth: controlAreaMaxWidth,
                    ...(labelWidth >= 90 && { minWidth: '44px' }) // Ensure Switch has space
                }}>
                    { children }
                </div>
            </div>
        );
    }
    // ... rest of component
});
```

### Phase 2: Update Form Component

**File:** `client/src/components/form/form.jsx`

**Changes:**

1. Detect Switch input type when rendering SettingRow
2. Pass `fullWidthLabel={true}` for Switch components
3. Optionally support other input types (radio, checkbox) if they need full-width labels

**Code Changes:**

```jsx
// In settingsMode rendering section:
if (settingsMode && type !== "hidden") {
  // Determine if this input type should have full-width label
  const fullWidthLabelTypes = ["switch", "radio", "checkbox"]; // Extensible list
  const fullWidthLabel = fullWidthLabelTypes.includes(type);

  return (
    <SettingRow
      key={name}
      label={label}
      description={description}
      error={errors[name]?.message}
      required={required}
      fullWidthLabel={fullWidthLabel} // NEW PROP
    >
      {/* ... existing Controller code ... */}
    </SettingRow>
  );
}
```

### Phase 3: Verify CollapsibleSettingRow

**File:** `client/src/components/form/collapsible-setting-row/collapsible-setting-row.jsx`

**Verification:**

- CollapsibleSettingRow uses `controlWidth='70%'` for display fields
- This should continue to work as `labelWidth` defaults to `40` when not provided
- `controlWidth` prop takes precedence over calculated width from `labelWidth`
- No changes needed unless we want to support custom label widths in collapsible rows

### Phase 4: Update Admin Console (if applicable)

**File:** `admin/console/src/components/form/setting-row/setting-row.jsx`

**Changes:**

- Apply same changes as client-side SettingRow component
- Ensure consistency across both codebases

**File:** `admin/console/src/components/form/form.jsx`

**Changes:**

- Apply same changes as client-side Form component

## Test Cases

### Unit Tests (to be created)

**Test File:** `client/src/components/form/setting-row/setting-row.test.jsx` (new)

**Test Cases:**

1. **Default Behavior (labelWidth not provided)**

   - Label area should have `maxWidth: '40%'`
   - Control area should use `controlWidth` prop or default to '60%'
   - Should match current behavior

2. **Explicit labelWidth**

   - Label area should have `maxWidth: '{labelWidth}%'` when provided
   - Control area should calculate width from `labelWidth` or use `controlWidth` if provided
   - Examples: `labelWidth={30}` → label `maxWidth: '30%'`, control `width: '70%'`

3. **Switch Component Integration (labelWidth >= 90)**

   - When Switch is rendered inside SettingRow with `labelWidth={95}`
   - Label area should have `maxWidth: '95%'`
   - Control area should have `width: 'auto'` and `minWidth: '44px'`
   - Label and description should not wrap unnecessarily
   - Switch should be right-aligned with minimal space

4. **Backward Compatibility**

   - Existing SettingRow usage without `labelWidth` prop should work unchanged
   - Control width prop should still work as before
   - Default behavior (40% label width) preserved

5. **Form Component Integration**
   - Form component should detect Switch type and pass `labelWidth={95}`
   - Radio/checkbox types should pass `labelWidth={90}` (if implemented)
   - Other input types should not receive `labelWidth` prop (defaults to 40)

### Integration Tests

**Test File:** `client/src/views/account/notifications.test.jsx` (new)

**Test Cases:**

1. **Notification Settings Page**

   - Switch components should have full-width labels
   - Descriptions should not wrap unnecessarily
   - Layout should match original design

2. **User Edit Form**
   - Text input fields should maintain 30% label width
   - Display fields should maintain 70% control width
   - Switch components (if any) should have full-width labels

### Manual Testing Checklist

1. **Notification Settings Page** (`/account/notifications`)

   - [ ] Switch labels have almost full width
   - [ ] Descriptions don't wrap unnecessarily
   - [ ] Switches are right-aligned
   - [ ] Layout looks correct in both light and dark mode

2. **User Edit Form** (`/account/users/edit`)

   - [ ] Text input labels are constrained to ~30%
   - [ ] Display fields have 70% control width
   - [ ] No layout regressions

3. **Other Settings Pages**
   - [ ] TFA settings (if uses switches)
   - [ ] Any other pages using Switch components

## Edge Cases and Considerations

1. **Multiple Input Types**

   - Solution is extensible: can add `'radio'`, `'checkbox'` to `fullWidthLabelTypes` array if needed
   - No breaking changes required

2. **Responsive Design**

   - Current implementation uses flexbox which is responsive
   - `minWidth: '44px'` ensures Switch has enough space on small screens
   - May need to adjust for mobile if issues arise

3. **Long Labels**

   - With full-width labels, very long text could push Switch off-screen
   - Consider adding `max-width` or text truncation if needed
   - Current implementation should handle this gracefully with flexbox

4. **CollapsibleSettingRow Compatibility**

   - CollapsibleSettingRow uses `controlWidth` prop, not `fullWidthLabel`
   - These are independent concerns and should not conflict
   - Verify no regressions in User Edit form

5. **Admin Console Consistency**
   - Both client and admin console should have same behavior
   - Ensure changes are applied to both codebases

## Implementation Checklist

- [ ] Update `client/src/components/form/setting-row/setting-row.jsx`

  - [ ] Add `fullWidthLabel` prop
  - [ ] Update JSDoc documentation
  - [ ] Implement conditional styling logic
  - [ ] Run ESLint and fix any errors

- [ ] Update `client/src/components/form/form.jsx`

  - [ ] Detect Switch input type
  - [ ] Pass `fullWidthLabel={true}` for Switch components
  - [ ] Run ESLint and fix any errors

- [ ] Update `admin/console/src/components/form/setting-row/setting-row.jsx` (if exists)

  - [ ] Apply same changes as client-side

- [ ] Update `admin/console/src/components/form/form.jsx` (if exists)

  - [ ] Apply same changes as client-side

- [ ] Create unit tests

  - [ ] Test default behavior
  - [ ] Test full-width label behavior
  - [ ] Test backward compatibility

- [ ] Manual testing

  - [ ] Notification Settings page
  - [ ] User Edit form
  - [ ] Other Switch usage locations

- [ ] Documentation
  - [ ] Update component JSDoc
  - [ ] Update any relevant README files

## Confidence Assessment

**Current Confidence Level: 95%**

**Confidence Factors:**

- ✅ Clear understanding of current implementation
- ✅ Well-defined problem statement
- ✅ Backward-compatible solution design
- ✅ Extensible approach for future input types
- ✅ Minimal code changes required

**Remaining Questions:**

1. What exact `labelWidth` value should Switch components use? (Proposed: 95)
2. Should radio and checkbox also get full-width labels? (Proposed: 90, extensible)
3. When `labelWidth >= 90`, should control use `auto` or calculated width? (Proposed: `auto` with `minWidth: '44px'`)
4. Do we need responsive breakpoints for mobile devices?
5. Should CollapsibleSettingRow also support `labelWidth` prop, or continue using `controlWidth` only?
6. Should we validate `labelWidth` prop (0-100 range) or allow any number?

**Assumptions:**

1. Switch component width is approximately 44px (needs verification)
2. Default `labelWidth` of 40 maintains current behavior
3. `controlWidth` prop takes precedence over calculated width from `labelWidth`
4. Admin console has similar structure to client codebase
5. Numeric prop provides better flexibility than boolean for future use cases

## Next Steps

1. **Review and Approval**

   - Review this design document
   - Answer remaining questions
   - Approve approach or suggest modifications

2. **Implementation**

   - Once approved, proceed with implementation following the checklist
   - Test thoroughly before marking as complete

3. **Documentation**

   - Update component documentation
   - Add examples of usage

4. **Follow-up**
   - Monitor for any issues in production
   - Consider adding other input types to full-width label support if needed








