# Team Portal Fix

Fixes for the team portal "not reflecting correctly" issue.

## Problem Summary

The team portal has several issues causing data to not reflect correctly:

1. **No `useTeam` hook** - Unlike other features, team has no React Query integration
2. **Hardcoded demo credentials** in TeamLogin
3. **Demo data** in TeamDashboard instead of API calls
4. **Raw fetch()** in TeamManagement without cache invalidation
5. **No real-time updates** when team data changes

## Files Included

| File | Purpose |
|------|---------|
| `DIAGNOSIS.md` | Detailed root cause analysis |
| `useTeam.ts` | New React Query hook for team data |
| `TeamLogin.tsx.fixed` | Fixed login component using real auth |
| `TeamManagement.tsx.fixed` | Fixed management using useTeam hook |
| `TeamDashboard.patch.md` | Patch instructions for dashboard |
| `test-team-api.sh` | API diagnostic script |

## Installation Steps

### Step 1: Create the useTeam Hook

```bash
# Copy the new hook to your project
cp useTeam.ts /path/to/kaa-notion-backend/kaa-app/src/hooks/useTeam.ts
```

Then update `kaa-app/src/hooks/index.ts`:

```typescript
// Add this line to exports
export * from './useTeam';
```

### Step 2: Replace TeamLogin

```bash
# Backup original
cp /path/to/kaa-app/src/components/TeamLogin.tsx \
   /path/to/kaa-app/src/components/TeamLogin.tsx.backup

# Copy fixed version
cp TeamLogin.tsx.fixed \
   /path/to/kaa-app/src/components/TeamLogin.tsx
```

### Step 3: Replace TeamManagement

```bash
# Backup original
cp /path/to/kaa-app/src/components/TeamManagement.tsx \
   /path/to/kaa-app/src/components/TeamManagement.tsx.backup

# Copy fixed version
cp TeamManagement.tsx.fixed \
   /path/to/kaa-app/src/components/TeamManagement.tsx
```

### Step 4: Update TeamDashboard

Follow the instructions in `TeamDashboard.patch.md` to update the dashboard component.

Key changes:
- Replace `loadTeamData()` with hooks
- Remove demo data
- Add loading states

### Step 5: Test the API

```bash
# Set your environment
export API_URL=http://localhost:3001
export AUTH_TOKEN=your_jwt_token

# Run diagnostics
chmod +x test-team-api.sh
./test-team-api.sh
```

## Verification Checklist

After applying fixes, verify:

- [ ] Team login works with real credentials
- [ ] Team dashboard shows real projects
- [ ] Team stats display correctly
- [ ] Adding a member reflects immediately
- [ ] Changing a role reflects immediately
- [ ] Removing a member reflects immediately
- [ ] Pending invites show correctly
- [ ] Multiple browser tabs stay in sync
- [ ] Page refresh shows correct state

## How the Fix Works

### Before (Broken Flow)

```
User Action → fetch() → API → Response → Manual setState()
                                              ↓
                          ❌ Other components don't know about change
                          ❌ Page refresh loses state
                          ❌ No automatic sync
```

### After (Fixed Flow)

```
User Action → useMutation() → API → Response → Cache Invalidation
                                                      ↓
                                   ✅ All useQuery() hooks refetch
                                   ✅ All components update automatically
                                   ✅ Data persists on refresh
```

## Key Code Changes

### useTeam Hook Pattern

```typescript
// Query keys for cache management
export const teamKeys = {
  all: ['team'] as const,
  members: () => [...teamKeys.all, 'members'] as const,
  member: (userId: string) => [...teamKeys.members(), userId] as const,
  // ...
};

// Mutation with automatic cache invalidation
export function useInviteTeamMember() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data) => teamApi('/api/team/invite', { method: 'POST', body: data }),
    onSuccess: () => {
      // This is the key - invalidate related queries
      queryClient.invalidateQueries({ queryKey: teamKeys.invites() });
      queryClient.invalidateQueries({ queryKey: teamKeys.stats() });
    },
  });
}
```

### Component Usage

```typescript
// Before (broken):
const [members, setMembers] = useState([]);
useEffect(() => {
  fetch('/api/team/members').then(r => r.json()).then(setMembers);
}, []);

// After (fixed):
const { members, isLoading } = useTeam();
// Automatically refetches when data changes!
```

## Troubleshooting

### "Cannot find module './useTeam'"
Make sure you added the export to `hooks/index.ts`

### "QueryClient not found"
Ensure your app is wrapped with `QueryClientProvider`

### "401 Unauthorized"
Check that tokens are being stored and sent correctly

### "Data not updating"
Clear React Query cache: `queryClient.clear()`

## Optional: Real-time Updates

For multi-user sync, add WebSocket integration:

```typescript
// In a component or hook:
import { useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';

function useTeamRealtimeUpdates() {
  const queryClient = useQueryClient();

  useEffect(() => {
    const ws = new WebSocket('ws://localhost:3001');

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);

      if (data.type === 'team-member-added' ||
          data.type === 'team-member-updated' ||
          data.type === 'team-member-removed') {
        // Invalidate team queries to trigger refetch
        queryClient.invalidateQueries({ queryKey: ['team'] });
      }
    };

    return () => ws.close();
  }, [queryClient]);
}
```

## Support

If issues persist after applying these fixes:

1. Check browser console for errors
2. Check network tab for failed API calls
3. Verify backend logs for server errors
4. Ensure database has correct team data
