#!/bin/bash
# modules/features/dashboard-setup.sh
# Module: Dashboard Setup
# Version: 2.0.0
# Description: Creates dashboard pages and layouts
# Depends: none
# Author: SaaS Template Team

set -e

# Module configuration
MODULE_NAME="dashboard-setup"
MODULE_VERSION="2.0.0"
PROJECT_NAME=${1:-"lean-saas-app"}

# Import shared utilities if available
if [[ -f "$(dirname "$0")/../../lib/logger.sh" ]]; then
    source "$(dirname "$0")/../../lib/logger.sh"
else
    # Fallback logging functions
    log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
    log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
    log_warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }
    log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
    log_step() { echo -e "\033[0;35m🚀 $1\033[0m"; }
fi

# ==============================================================================
# MODULE FUNCTIONS
# ==============================================================================

#!/bin/bash
# Module 7: Dashboard Setup

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_dashboard() {
    log_info "Setting up dashboard..."
    
    cd frontend/src/app/dashboard
    
    # Create dashboard pages
    mkdir -p {projects,settings}
    
    create_dashboard_pages
    create_project_pages
    create_settings_pages
    
    cd ../../../..
    log_success "Dashboard setup completed"
}

create_dashboard_pages() {
    log_info "Creating dashboard pages..."
    
    cat > page.tsx << 'TSX'
// app/dashboard/page.tsx
import { requireAuth, getProfile } from '@/lib/auth/server'
import { DashboardLayout } from '@/components/layouts/DashboardLayout'
import { createAuthClient } from '@/lib/auth/server'

export default async function DashboardPage() {
  const user = await requireAuth()
  const profile = await getProfile(user.id)
  const supabase = await createAuthClient()
  
  // Get user statistics
  const { data: projects } = await supabase
    .from('projects')
    .select('id')
    .eq('created_by', user.id)
  
  const projectCount = projects?.length || 0
  
  return (
    <DashboardLayout>
      <div className="p-6">
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900">
            Welcome back, {profile?.full_name || user.email}!
          </h1>
          <p className="text-gray-600">
            Here's what's happening with your account today.
          </p>
        </div>
        
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="w-8 h-8 bg-indigo-500 rounded-md flex items-center justify-center">
                    <svg className="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M7 3a1 1 0 000 2h6a1 1 0 100-2H7zM4 7a1 1 0 011-1h10a1 1 0 110 2H5a1 1 0 01-1-1zM2 11a2 2 0 012-2h12a2 2 0 012 2v4a2 2 0 01-2 2H4a2 2 0 01-2-2v-4z" />
                    </svg>
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Total Projects
                    </dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {projectCount}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
          
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="w-8 h-8 bg-green-500 rounded-md flex items-center justify-center">
                    <svg className="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Plan Type
                    </dt>
                    <dd className="text-lg font-medium text-gray-900 capitalize">
                      {profile?.plan_type || 'Free'}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
          
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className="w-8 h-8 bg-yellow-500 rounded-md flex items-center justify-center">
                    <svg className="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clipRule="evenodd" />
                    </svg>
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      Member Since
                    </dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {new Date(profile?.created_at || user.created_at).toLocaleDateString()}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div className="mt-8 bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">
              Quick Actions
            </h3>
            <div className="mt-5">
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
                <a
                  href="/dashboard/projects"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200"
                >
                  View Projects
                </a>
                <a
                  href="/dashboard/settings"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-gray-700 bg-gray-100 hover:bg-gray-200"
                >
                  Account Settings
                </a>
                <a
                  href="/dashboard/billing"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-green-700 bg-green-100 hover:bg-green-200"
                >
                  Billing
                </a>
                <a
                  href="/support"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-purple-700 bg-purple-100 hover:bg-purple-200"
                >
                  Get Support
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  )
}
TSX
}

create_project_pages() {
    log_info "Creating project pages..."
    
    cat > projects/page.tsx << 'TSX'
// app/dashboard/projects/page.tsx
import { requireAuth } from '@/lib/auth/server'
import { DashboardLayout } from '@/components/layouts/DashboardLayout'
import { createAuthClient } from '@/lib/auth/server'
import { Button } from '@/components/ui/Button'
import Link from 'next/link'

export default async function ProjectsPage() {
  const user = await requireAuth()
  const supabase = await createAuthClient()
  
  const { data: projects } = await supabase
    .from('projects')
    .select('*')
    .eq('created_by', user.id)
    .order('created_at', { ascending: false })
  
  return (
    <DashboardLayout>
      <div className="p-6">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-gray-900">Projects</h1>
          <Button asChild>
            <Link href="/dashboard/projects/new">
              Create Project
            </Link>
          </Button>
        </div>
        
        {projects && projects.length > 0 ? (
          <div className="bg-white shadow overflow-hidden sm:rounded-md">
            <ul className="divide-y divide-gray-200">
              {projects.map((project) => (
                <li key={project.id}>
                  <div className="px-4 py-4 flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-10 w-10">
                        <div className="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                          <svg className="h-6 w-6 text-gray-500" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M7 3a1 1 0 000 2h6a1 1 0 100-2H7zM4 7a1 1 0 011-1h10a1 1 0 110 2H5a1 1 0 01-1-1zM2 11a2 2 0 012-2h12a2 2 0 012 2v4a2 2 0 01-2 2H4a2 2 0 01-2-2v-4z" />
                          </svg>
                        </div>
                      </div>
                      <div className="ml-4">
                        <div className="flex items-center">
                          <div className="text-sm font-medium text-gray-900">
                            {project.name}
                          </div>
                          <div className={`ml-2 flex-shrink-0 flex ${{
                            active: 'text-green-800 bg-green-100',
                            archived: 'text-yellow-800 bg-yellow-100',
                            deleted: 'text-red-800 bg-red-100'
                          }[project.status as string]}`}>
                            <p className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full">
                              {project.status}
                            </p>
                          </div>
                        </div>
                        <div className="text-sm text-gray-500">
                          {project.description || 'No description'}
                        </div>
                        <div className="text-xs text-gray-400">
                          Created {new Date(project.created_at).toLocaleDateString()}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Button variant="outline" size="sm">
                        Edit
                      </Button>
                      <Button variant="ghost" size="sm">
                        Archive
                      </Button>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        ) : (
          <div className="text-center">
            <svg
              className="mx-auto h-12 w-12 text-gray-400"
              stroke="currentColor"
              fill="none"
              viewBox="0 0 48 48"
            >
              <path
                d="M34 40h10v-4a6 6 0 00-10.712-3.714M34 40H14m20 0v-4a9.971 9.971 0 00-.712-3.714M14 40H4v-4a6 6 0 0110.713-3.714M14 40v-4c0-1.313.253-2.566.713-3.714m0 0A10.003 10.003 0 0124 26c4.21 0 7.813 2.602 9.288 6.286M30 14a6 6 0 11-12 0 6 6 0 0112 0zm12 6a4 4 0 11-8 0 4 4 0 018 0zm-28 0a4 4 0 11-8 0 4 4 0 018 0z"
                strokeWidth={2}
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900">No projects</h3>
            <p className="mt-1 text-sm text-gray-500">
              Get started by creating a new project.
            </p>
            <div className="mt-6">
              <Button asChild>
                <Link href="/dashboard/projects/new">
                  Create your first project
                </Link>
              </Button>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  )
}
TSX
}

create_settings_pages() {
    log_info "Creating settings pages..."
    
    cat > settings/page.tsx << 'TSX'
// app/dashboard/settings/page.tsx
'use client'

import { DashboardLayout } from '@/components/layouts/DashboardLayout'
import { useProfile } from '@/hooks/auth/useProfile'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Label } from '@/components/ui/Label'
import { useState } from 'react'

export default function SettingsPage() {
  const { profile, loading, updateProfile } = useProfile()
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')
  
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setSaving(true)
    setMessage('')
    
    const formData = new FormData(e.currentTarget)
    
    try {
      await updateProfile({
        full_name: formData.get('fullName') as string,
      })
      setMessage('Profile updated successfully!')
    } catch (error) {
      setMessage('Failed to update profile')
    } finally {
      setSaving(false)
    }
  }
  
  if (loading) {
    return (
      <DashboardLayout>
        <div className="p-6">Loading...</div>
      </DashboardLayout>
    )
  }
  
  return (
    <DashboardLayout>
      <div className="p-6">
        <h1 className="text-2xl font-bold mb-6">Account Settings</h1>
        
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
              Profile Information
            </h3>
            
            {message && (
              <div className={`mb-4 p-3 rounded ${
                message.includes('success') 
                  ? 'bg-green-50 text-green-700 border border-green-200' 
                  : 'bg-red-50 text-red-700 border border-red-200'
              }`}>
                {message}
              </div>
            )}
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <Label htmlFor="email">Email address</Label>
                <Input
                  id="email"
                  type="email"
                  value={profile?.email || ''}
                  disabled
                  className="mt-1"
                />
                <p className="text-sm text-gray-500 mt-1">
                  Email cannot be changed from here.
                </p>
              </div>
              
              <div>
                <Label htmlFor="fullName">Full name</Label>
                <Input
                  id="fullName"
                  name="fullName"
                  type="text"
                  defaultValue={profile?.full_name || ''}
                  className="mt-1"
                />
              </div>
              
              <div>
                <Label htmlFor="planType">Plan type</Label>
                <Input
                  id="planType"
                  type="text"
                  value={profile?.plan_type || 'Free'}
                  disabled
                  className="mt-1 capitalize"
                />
              </div>
              
              <Button type="submit" disabled={saving}>
                {saving ? 'Saving...' : 'Save changes'}
              </Button>
            </form>
          </div>
        </div>
        
        <div className="mt-6 bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
              Account Actions
            </h3>
            
            <div className="space-y-4">
              <div>
                <Button variant="outline" asChild>
                  <a href="/dashboard/billing">
                    Manage Billing
                  </a>
                </Button>
              </div>
              
              <div>
                <Button variant="outline">
                  Export Data
                </Button>
              </div>
              
              <div className="pt-4 border-t">
                <Button variant="destructive">
                  Delete Account
                </Button>
                <p className="text-sm text-gray-500 mt-1">
                  This action cannot be undone.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  )
}
TSX
}

setup_dashboard

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_step "Starting dashboard-setup"
    setup_dashboard-setup
    log_success "dashboard-setup completed!"
}

# Error handling
trap 'log_error "Module failed at line $LINENO"' ERR

# Execute main function
main "$@"
