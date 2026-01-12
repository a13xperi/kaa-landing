/**
 * useTeam Hook
 *
 * React Query-based hook for team data management.
 * Follows the same pattern as useProjects, useDeliverables, etc.
 *
 * FILE: kaa-app/src/hooks/useTeam.ts
 *
 * After creating this file, add to kaa-app/src/hooks/index.ts:
 *   export * from './useTeam';
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// ============================================
// Types
// ============================================

export type TeamRole = 'OWNER' | 'ADMIN' | 'DESIGNER' | 'VIEWER';

export interface TeamMember {
  id: string;
  userId: string;
  email: string;
  name: string;
  role: TeamRole;
  status: 'active' | 'inactive' | 'pending';
  createdAt: string;
  updatedAt: string;
  projects?: string[];
}

export interface TeamInvite {
  id: string;
  email: string;
  role: TeamRole;
  token: string;
  expiresAt: string;
  invitedBy: string;
  createdAt: string;
}

export interface TeamStats {
  totalMembers: number;
  activeMembers: number;
  pendingInvites: number;
  activeProjects: number;
  membersByRole: Record<TeamRole, number>;
}

export interface TeamPermissions {
  canManageTeam: boolean;
  canInviteMembers: boolean;
  canRemoveMembers: boolean;
  canChangeRoles: boolean;
  canAccessBilling: boolean;
  canEditProjects: boolean;
  canViewProjects: boolean;
  canUploadDeliverables: boolean;
  canManageMilestones: boolean;
}

// ============================================
// Query Keys (for cache management)
// ============================================

export const teamKeys = {
  all: ['team'] as const,
  members: () => [...teamKeys.all, 'members'] as const,
  member: (userId: string) => [...teamKeys.members(), userId] as const,
  memberProjects: (userId: string) => [...teamKeys.member(userId), 'projects'] as const,
  invites: () => [...teamKeys.all, 'invites'] as const,
  invite: (id: string) => [...teamKeys.invites(), id] as const,
  stats: () => [...teamKeys.all, 'stats'] as const,
  permissions: (role: TeamRole) => [...teamKeys.all, 'permissions', role] as const,
  projectTeam: (projectId: string) => [...teamKeys.all, 'project', projectId] as const,
};

// ============================================
// API Helper
// ============================================

const API_BASE = import.meta.env.VITE_API_URL || '';

async function teamApi<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = localStorage.getItem('token');

  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'Request failed' }));
    throw new Error(error.message || error.error || 'API request failed');
  }

  return response.json();
}

// ============================================
// Query Hooks (Read Operations)
// ============================================

/**
 * Fetch all team members
 */
export function useTeamMembers() {
  return useQuery({
    queryKey: teamKeys.members(),
    queryFn: () => teamApi<{ members: TeamMember[] }>('/api/team/members'),
    staleTime: 30 * 1000, // 30 seconds
    select: (data) => data.members,
  });
}

/**
 * Fetch a specific team member
 */
export function useTeamMember(userId: string) {
  return useQuery({
    queryKey: teamKeys.member(userId),
    queryFn: () => teamApi<{ member: TeamMember }>(`/api/team/members/${userId}`),
    enabled: !!userId,
    staleTime: 30 * 1000,
    select: (data) => data.member,
  });
}

/**
 * Fetch current user's team membership
 */
export function useMyTeamMembership() {
  return useQuery({
    queryKey: [...teamKeys.members(), 'me'],
    queryFn: () => teamApi<{ member: TeamMember; permissions: TeamPermissions }>('/api/team/members/me'),
    staleTime: 60 * 1000, // 1 minute
  });
}

/**
 * Fetch projects assigned to a team member
 */
export function useMemberProjects(userId: string) {
  return useQuery({
    queryKey: teamKeys.memberProjects(userId),
    queryFn: () => teamApi<{ projects: any[] }>(`/api/team/members/${userId}/projects`),
    enabled: !!userId,
    staleTime: 30 * 1000,
    select: (data) => data.projects,
  });
}

/**
 * Fetch team members assigned to a project
 */
export function useProjectTeam(projectId: string) {
  return useQuery({
    queryKey: teamKeys.projectTeam(projectId),
    queryFn: () => teamApi<{ team: TeamMember[] }>(`/api/team/projects/${projectId}/team`),
    enabled: !!projectId,
    staleTime: 30 * 1000,
    select: (data) => data.team,
  });
}

/**
 * Fetch pending invites
 */
export function useTeamInvites() {
  return useQuery({
    queryKey: teamKeys.invites(),
    queryFn: () => teamApi<{ invites: TeamInvite[] }>('/api/team/invites'),
    staleTime: 30 * 1000,
    select: (data) => data.invites,
  });
}

/**
 * Fetch team statistics
 */
export function useTeamStats() {
  return useQuery({
    queryKey: teamKeys.stats(),
    queryFn: () => teamApi<{ stats: TeamStats }>('/api/team/stats'),
    staleTime: 60 * 1000,
    select: (data) => data.stats,
  });
}

/**
 * Fetch permissions for a role
 */
export function useRolePermissions(role: TeamRole) {
  return useQuery({
    queryKey: teamKeys.permissions(role),
    queryFn: () => teamApi<{ permissions: TeamPermissions }>(`/api/team/permissions/${role}`),
    enabled: !!role,
    staleTime: 5 * 60 * 1000, // 5 minutes (permissions rarely change)
    select: (data) => data.permissions,
  });
}

// ============================================
// Mutation Hooks (Write Operations)
// ============================================

/**
 * Invite a new team member
 */
export function useInviteTeamMember() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { email: string; role: TeamRole }) =>
      teamApi<{ invite: TeamInvite }>('/api/team/invite', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    onSuccess: () => {
      // Invalidate invites list to trigger refetch
      queryClient.invalidateQueries({ queryKey: teamKeys.invites() });
      queryClient.invalidateQueries({ queryKey: teamKeys.stats() });
    },
  });
}

/**
 * Resend an invite
 */
export function useResendInvite() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (inviteId: string) =>
      teamApi<{ invite: TeamInvite }>(`/api/team/invite/${inviteId}/resend`, {
        method: 'POST',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: teamKeys.invites() });
    },
  });
}

/**
 * Cancel an invite
 */
export function useCancelInvite() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (inviteId: string) =>
      teamApi<void>(`/api/team/invite/${inviteId}`, {
        method: 'DELETE',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: teamKeys.invites() });
      queryClient.invalidateQueries({ queryKey: teamKeys.stats() });
    },
  });
}

/**
 * Update team member role
 */
export function useUpdateMemberRole() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ memberId, role }: { memberId: string; role: TeamRole }) =>
      teamApi<{ member: TeamMember }>(`/api/team/members/${memberId}`, {
        method: 'PATCH',
        body: JSON.stringify({ role }),
      }),
    onSuccess: (_, variables) => {
      // Invalidate specific member and members list
      queryClient.invalidateQueries({ queryKey: teamKeys.member(variables.memberId) });
      queryClient.invalidateQueries({ queryKey: teamKeys.members() });
      queryClient.invalidateQueries({ queryKey: teamKeys.stats() });
    },
  });
}

/**
 * Remove a team member
 */
export function useRemoveMember() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (memberId: string) =>
      teamApi<void>(`/api/team/members/${memberId}`, {
        method: 'DELETE',
      }),
    onSuccess: (_, memberId) => {
      queryClient.invalidateQueries({ queryKey: teamKeys.member(memberId) });
      queryClient.invalidateQueries({ queryKey: teamKeys.members() });
      queryClient.invalidateQueries({ queryKey: teamKeys.stats() });
    },
  });
}

/**
 * Reactivate an inactive team member
 */
export function useReactivateMember() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (memberId: string) =>
      teamApi<{ member: TeamMember }>(`/api/team/members/${memberId}`, {
        method: 'PATCH',
        body: JSON.stringify({ status: 'active' }),
      }),
    onSuccess: (_, memberId) => {
      queryClient.invalidateQueries({ queryKey: teamKeys.member(memberId) });
      queryClient.invalidateQueries({ queryKey: teamKeys.members() });
      queryClient.invalidateQueries({ queryKey: teamKeys.stats() });
    },
  });
}

/**
 * Assign member to project
 */
export function useAssignToProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ memberId, projectId }: { memberId: string; projectId: string }) =>
      teamApi<void>(`/api/team/members/${memberId}/projects/${projectId}`, {
        method: 'POST',
      }),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: teamKeys.memberProjects(variables.memberId) });
      queryClient.invalidateQueries({ queryKey: teamKeys.projectTeam(variables.projectId) });
    },
  });
}

/**
 * Unassign member from project
 */
export function useUnassignFromProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ memberId, projectId }: { memberId: string; projectId: string }) =>
      teamApi<void>(`/api/team/members/${memberId}/projects/${projectId}`, {
        method: 'DELETE',
      }),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: teamKeys.memberProjects(variables.memberId) });
      queryClient.invalidateQueries({ queryKey: teamKeys.projectTeam(variables.projectId) });
    },
  });
}

// ============================================
// Combined Hook (for convenience)
// ============================================

/**
 * Combined hook for common team operations
 */
export function useTeam() {
  const members = useTeamMembers();
  const invites = useTeamInvites();
  const stats = useTeamStats();
  const myMembership = useMyTeamMembership();

  const inviteMember = useInviteTeamMember();
  const updateRole = useUpdateMemberRole();
  const removeMember = useRemoveMember();
  const reactivateMember = useReactivateMember();
  const cancelInvite = useCancelInvite();
  const resendInvite = useResendInvite();

  return {
    // Data
    members: members.data ?? [],
    invites: invites.data ?? [],
    stats: stats.data,
    myMembership: myMembership.data,

    // Loading states
    isLoading: members.isLoading || invites.isLoading || stats.isLoading,
    isLoadingMembers: members.isLoading,
    isLoadingInvites: invites.isLoading,
    isLoadingStats: stats.isLoading,

    // Error states
    error: members.error || invites.error || stats.error,

    // Refetch functions
    refetchMembers: members.refetch,
    refetchInvites: invites.refetch,
    refetchStats: stats.refetch,
    refetchAll: () => {
      members.refetch();
      invites.refetch();
      stats.refetch();
    },

    // Mutations
    inviteMember: inviteMember.mutateAsync,
    updateRole: updateRole.mutateAsync,
    removeMember: removeMember.mutateAsync,
    reactivateMember: reactivateMember.mutateAsync,
    cancelInvite: cancelInvite.mutateAsync,
    resendInvite: resendInvite.mutateAsync,

    // Mutation states
    isInviting: inviteMember.isPending,
    isUpdatingRole: updateRole.isPending,
    isRemoving: removeMember.isPending,
  };
}

export default useTeam;
