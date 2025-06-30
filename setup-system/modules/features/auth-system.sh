#!/bin/bash
# modules/features/auth-system.sh - UPDATED: Fixed syntax error with brace expansion
# Module: Authentication System
# Version: 2.0.0
# Description: Sets up authentication with Supabase
# Depends: none
# Author: SaaS Template Team

set -e

# Module configuration
MODULE_NAME="auth-system"
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

setup_auth_system() {
    log_info "Setting up authentication system..."
    
    cd frontend/src
    
    # Create auth-related directories - Fixed brace expansion
    mkdir -p app/auth/login app/auth/register app/auth/forgot-password app/auth/callback
    mkdir -p lib/auth
    mkdir -p hooks/auth
    
    create_auth_config
    create_auth_hooks
    create_auth_pages
    create_auth_middleware
    
    cd ../..
    log_success "Authentication system setup completed"
}

create_auth_config() {
    log_info "Creating auth configuration..."
    
    cat > lib/auth/config.ts << 'TS'
// lib/auth/config.ts
export const authConfig = {
  signIn: {
    redirectTo: '/dashboard',
  },
  signUp: {
    redirectTo: '/auth/callback?next=/dashboard',
  },
  signOut: {
    redirectTo: '/',
  },
  passwordReset: {
    redirectTo: '/auth/callback?next=/dashboard',
  },
}

export const authRoutes = {
  signIn: '/auth/login',
  signUp: '/auth/register',
  forgotPassword: '/auth/forgot-password',
  callback: '/auth/callback',
}

export const protectedRoutes = [
  '/dashboard',
  '/settings',
  '/billing',
]

export const publicRoutes = [
  '/',
  '/auth/login',
  '/auth/register', 
  '/auth/forgot-password',
  '/auth/callback',
  '/pricing',
  '/about',
]
TS

    cat > lib/auth/server.ts << 'TS'
// lib/auth/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import { authRoutes } from './config'

export async function createAuthClient() {
  const cookieStore = await cookies()
  
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Server component context
          }
        },
      },
    }
  )
}

export async function getUser() {
  const supabase = await createAuthClient()
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    return null
  }
  
  return user
}

export async function requireAuth() {
  const user = await getUser()
  
  if (!user) {
    redirect(authRoutes.signIn)
  }
  
  return user
}

export async function getProfile(userId: string) {
  const supabase = await createAuthClient()
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single()
    
  if (error) {
    console.error('Error fetching profile:', error)
    return null
  }
  
  return profile
}
TS
}

create_auth_hooks() {
    log_info "Creating auth hooks..."
    
    cat > hooks/auth/useAuth.ts << 'TS'
// hooks/auth/useAuth.ts
'use client'

import { createClient } from '@/lib/supabase/client'
import { User } from '@supabase/supabase-js'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { authConfig } from '@/lib/auth/config'

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const supabase = createClient()
  
  useEffect(() => {
    // Get initial session
    const getInitialSession = async () => {
      const { data: { session } } = await supabase.auth.getSession()
      setUser(session?.user ?? null)
      setLoading(false)
    }
    
    getInitialSession()
    
    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setUser(session?.user ?? null)
        setLoading(false)
        
        if (event === 'SIGNED_IN') {
          router.push(authConfig.signIn.redirectTo)
        } else if (event === 'SIGNED_OUT') {
          router.push(authConfig.signOut.redirectTo)
        }
      }
    )
    
    return () => subscription.unsubscribe()
  }, [router, supabase.auth])
  
  const signOut = async () => {
    await supabase.auth.signOut()
  }
  
  return {
    user,
    loading,
    signOut,
    isAuthenticated: !!user,
  }
}
TS

    cat > hooks/auth/useProfile.ts << 'TS'
// hooks/auth/useProfile.ts
'use client'

import { createClient } from '@/lib/supabase/client'
import { useAuth } from './useAuth'
import { useEffect, useState } from 'react'

interface Profile {
  id: string
  email: string
  full_name: string | null
  avatar_url: string | null
  plan_type: 'free' | 'pro' | 'enterprise'
  onboarded: boolean
  created_at: string
  updated_at: string
}

export function useProfile() {
  const { user, loading: authLoading } = useAuth()
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const supabase = createClient()
  
  useEffect(() => {
    if (!user || authLoading) {
      setLoading(authLoading)
      return
    }
    
    const fetchProfile = async () => {
      try {
        setLoading(true)
        const { data, error } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single()
          
        if (error) {
          setError(error.message)
        } else {
          setProfile(data)
        }
      } catch (err) {
        setError('Failed to fetch profile')
      } finally {
        setLoading(false)
      }
    }
    
    fetchProfile()
  }, [user, authLoading, supabase])
  
  const updateProfile = async (updates: Partial<Profile>) => {
    if (!user) return
    
    try {
      const { data, error } = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .single()
        
      if (error) {
        throw error
      }
      
      setProfile(data)
      return data
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update profile')
      throw err
    }
  }
  
  return {
    profile,
    loading,
    error,
    updateProfile,
  }
}
TS
}

create_auth_pages() {
    log_info "Creating auth pages..."
    
    # Login page
    cat > app/auth/login/page.tsx << 'TSX'
// app/auth/login/page.tsx
import { Metadata } from 'next'
import { LoginForm } from '@/components/auth/LoginForm'
import { getUser } from '@/lib/auth/server'
import { redirect } from 'next/navigation'
import { authConfig } from '@/lib/auth/config'

export const metadata: Metadata = {
  title: 'Sign In',
  description: 'Sign in to your account',
}

export default async function LoginPage() {
  const user = await getUser()
  
  if (user) {
    redirect(authConfig.signIn.redirectTo)
  }
  
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to your account
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Or{' '}
            <a
              href="/auth/register"
              className="font-medium text-indigo-600 hover:text-indigo-500"
            >
              create a new account
            </a>
          </p>
        </div>
        <LoginForm />
      </div>
    </div>
  )
}
TSX

    # Register page
    cat > app/auth/register/page.tsx << 'TSX'
// app/auth/register/page.tsx
import { Metadata } from 'next'
import { RegisterForm } from '@/components/auth/RegisterForm'
import { getUser } from '@/lib/auth/server'
import { redirect } from 'next/navigation'
import { authConfig } from '@/lib/auth/config'

export const metadata: Metadata = {
  title: 'Sign Up',
  description: 'Create a new account',
}

export default async function RegisterPage() {
  const user = await getUser()
  
  if (user) {
    redirect(authConfig.signIn.redirectTo)
  }
  
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Create your account
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Or{' '}
            <a
              href="/auth/login"
              className="font-medium text-indigo-600 hover:text-indigo-500"
            >
              sign in to your existing account
            </a>
          </p>
        </div>
        <RegisterForm />
      </div>
    </div>
  )
}
TSX

    # Callback page
    cat > app/auth/callback/page.tsx << 'TSX'
// app/auth/callback/page.tsx
import { createAuthClient } from '@/lib/auth/server'
import { redirect } from 'next/navigation'
import { NextRequest } from 'next/server'

export default async function AuthCallbackPage({
  searchParams,
}: {
  searchParams: { [key: string]: string | string[] | undefined }
}) {
  const next = typeof searchParams.next === 'string' ? searchParams.next : '/dashboard'
  const supabase = await createAuthClient()
  
  const { data, error } = await supabase.auth.getUser()
  
  if (error || !data.user) {
    redirect('/auth/login')
  }
  
  redirect(next)
}
TSX
}

create_auth_middleware() {
    log_info "Creating auth middleware..."
    
    cat > ../../middleware.ts << 'TS'
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'
import { protectedRoutes, publicRoutes, authRoutes } from '@/lib/auth/config'

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  
  // Create Supabase client
  let supabaseResponse = NextResponse.next({ request })
  
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => 
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )
  
  const { data: { user } } = await supabase.auth.getUser()
  
  // Check if route is protected
  const isProtectedRoute = protectedRoutes.some(route => 
    pathname.startsWith(route)
  )
  
  // Check if route is public
  const isPublicRoute = publicRoutes.some(route => 
    pathname === route || pathname.startsWith(route)
  )
  
  // Redirect unauthenticated users from protected routes
  if (isProtectedRoute && !user) {
    const url = request.nextUrl.clone()
    url.pathname = authRoutes.signIn
    url.searchParams.set('next', pathname)
    return NextResponse.redirect(url)
  }
  
  // Redirect authenticated users from auth pages
  if (user && pathname.startsWith('/auth') && pathname !== '/auth/callback') {
    const url = request.nextUrl.clone()
    url.pathname = '/dashboard'
    return NextResponse.redirect(url)
  }
  
  return supabaseResponse
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
TS
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_step "Starting auth-system"
    setup_auth_system
    log_success "auth-system completed!"
}

# Error handling
trap 'log_error "Module failed at line $LINENO"' ERR

# Execute main function
main "$@"