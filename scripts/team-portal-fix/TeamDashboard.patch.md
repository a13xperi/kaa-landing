# TeamDashboard.tsx - Required Changes

The TeamDashboard component currently uses demo data via `loadTeamData()`.
Here are the specific changes needed to use real data.

## File: `kaa-app/src/components/TeamDashboard.tsx`

### 1. Add Imports

```diff
 import React, { useState, useEffect } from 'react';
+import { useMemberProjects, useMyTeamMembership } from '../hooks/useTeam';
+import { useProjects } from '../hooks/useProjects';
+import { useDeliverables } from '../hooks/useDeliverables';
 import './TeamDashboard.css';
```

### 2. Replace Demo Data Loading

**REMOVE this entire function:**
```typescript
// DELETE THIS:
const loadTeamData = () => {
  // Demo projects
  setProjects([
    {
      id: '1',
      name: '123 Main Street Renovation',
      // ... demo data
    },
    // ... more demo data
  ]);

  // Demo activity
  setClientActivity([...]);

  // Demo deliverables
  setDeliverables([...]);
};
```

**REPLACE with hooks:**
```typescript
const TeamDashboard: React.FC<TeamDashboardProps> = ({ teamMember, role, onLogout }) => {
  const [currentView, setCurrentView] = useState<'dashboard' | 'projects' | ...>('dashboard');

  // Fetch real data using hooks
  const { data: membership, isLoading: loadingMembership } = useMyTeamMembership();
  const { data: myProjects, isLoading: loadingProjects } = useMemberProjects(
    membership?.member?.userId || ''
  );
  const { data: allProjects } = useProjects({
    assignedTo: membership?.member?.userId
  });

  // Derive stats from real data
  const stats = {
    totalProjects: myProjects?.length || 0,
    activeProjects: myProjects?.filter(p => p.status === 'active').length || 0,
    pendingDeliverables: myProjects?.reduce(
      (sum, p) => sum + (p.pendingDeliverables || 0), 0
    ) || 0,
  };

  // Loading state
  if (loadingMembership || loadingProjects) {
    return <div className="loading">Loading dashboard...</div>;
  }

  // ... rest of component
};
```

### 3. Update Project Cards

**CHANGE:**
```diff
-{projects.map((project) => (
+{myProjects?.map((project) => (
   <div key={project.id} className="project-card">
-    <h4>{project.name}</h4>
+    <h4>{project.name || project.title}</h4>
     {/* ... */}
   </div>
 ))}
```

### 4. Remove useEffect with loadTeamData

**DELETE:**
```typescript
// DELETE THIS:
useEffect(() => {
  loadTeamData();
}, []);
```

### 5. Add Real-time Updates (Optional Enhancement)

```typescript
import { useRealtimeNotifications } from '../hooks/useRealtimeNotifications';

// Inside component:
useRealtimeNotifications({
  onProjectUpdate: () => {
    // Queries will auto-refetch due to React Query
  },
  onDeliverableUpdate: () => {
    // Auto handled
  },
});
```

---

## Complete Fixed Component Structure

```typescript
import React, { useState } from 'react';
import { useMemberProjects, useMyTeamMembership } from '../hooks/useTeam';
import { useDeliverables } from '../hooks/useDeliverables';
import { useMessages } from '../hooks/useMessages';
import { useNotifications } from '../hooks/useNotifications';
import ErrorBoundary from './ErrorBoundary';
import MessagingSystem from './MessagingSystem';
import NotificationSystem from './NotificationSystem';
import './TeamDashboard.css';

interface TeamDashboardProps {
  teamMember: {
    id: string;
    name: string;
    email: string;
    role: string;
  };
  role: string;
  onLogout: () => void;
}

const TeamDashboard: React.FC<TeamDashboardProps> = ({ teamMember, role, onLogout }) => {
  const [currentView, setCurrentView] = useState<string>('dashboard');

  // Real data hooks
  const { data: membership, isLoading: loadingMembership } = useMyTeamMembership();
  const { data: projects, isLoading: loadingProjects } = useMemberProjects(
    teamMember.id || membership?.member?.userId || ''
  );

  // Derived statistics
  const stats = React.useMemo(() => ({
    totalProjects: projects?.length || 0,
    activeProjects: projects?.filter((p: any) => p.status === 'active').length || 0,
    pendingDeliverables: projects?.reduce(
      (sum: number, p: any) => sum + (p.pendingDeliverables || 0),
      0
    ) || 0,
    recentActivity: projects?.filter(
      (p: any) => new Date(p.updatedAt) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    ).length || 0,
  }), [projects]);

  // Loading state
  if (loadingMembership || loadingProjects) {
    return (
      <div className="team-dashboard loading">
        <div className="loading-spinner"></div>
        <p>Loading your dashboard...</p>
      </div>
    );
  }

  return (
    <div className="team-dashboard">
      <header className="dashboard-header">
        <div className="welcome-section">
          <h1>Welcome, {teamMember.name}!</h1>
          <span className="role-badge">{role}</span>
        </div>
        <button className="logout-btn" onClick={onLogout}>
          Sign Out
        </button>
      </header>

      <nav className="dashboard-nav">
        {['dashboard', 'projects', 'deliverables', 'messages', 'notifications'].map((view) => (
          <button
            key={view}
            className={`nav-btn ${currentView === view ? 'active' : ''}`}
            onClick={() => setCurrentView(view)}
          >
            {view.charAt(0).toUpperCase() + view.slice(1)}
          </button>
        ))}
      </nav>

      <main className="dashboard-content">
        {currentView === 'dashboard' && (
          <ErrorBoundary>
            <div className="stats-grid">
              <div className="stat-card">
                <span className="stat-value">{stats.totalProjects}</span>
                <span className="stat-label">Total Projects</span>
              </div>
              <div className="stat-card">
                <span className="stat-value">{stats.activeProjects}</span>
                <span className="stat-label">Active</span>
              </div>
              <div className="stat-card">
                <span className="stat-value">{stats.pendingDeliverables}</span>
                <span className="stat-label">Pending Deliverables</span>
              </div>
              <div className="stat-card">
                <span className="stat-value">{stats.recentActivity}</span>
                <span className="stat-label">Updated This Week</span>
              </div>
            </div>

            <section className="projects-section">
              <h2>Your Projects</h2>
              {projects && projects.length > 0 ? (
                <div className="projects-grid">
                  {projects.map((project: any) => (
                    <div key={project.id} className="project-card">
                      <h3>{project.name || project.title}</h3>
                      <p className="project-status">{project.status}</p>
                      <p className="project-client">{project.clientName}</p>
                      <button className="view-btn">View Details</button>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="empty-state">No projects assigned yet.</p>
              )}
            </section>
          </ErrorBoundary>
        )}

        {currentView === 'messages' && (
          <ErrorBoundary>
            <MessagingSystem userId={teamMember.id} />
          </ErrorBoundary>
        )}

        {currentView === 'notifications' && (
          <ErrorBoundary>
            <NotificationSystem userId={teamMember.id} />
          </ErrorBoundary>
        )}

        {/* Add other views similarly */}
      </main>
    </div>
  );
};

export default TeamDashboard;
```

---

## Key Changes Summary

| Before | After |
|--------|-------|
| `loadTeamData()` with hardcoded data | `useMyTeamMembership()` + `useMemberProjects()` hooks |
| `useState` for projects/activity | Hooks return data directly |
| Manual `useEffect` to load | React Query handles fetching |
| No loading states | Proper loading/error states |
| No cache invalidation | Automatic via React Query |
| No real-time updates | Can add `useRealtimeNotifications` |
