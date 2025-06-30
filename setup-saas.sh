#!/bin/bash
# Enhanced Lean SaaS Template Setup - REFACTORED
# Author: AI Assistant
# Description: Creates a production-ready SaaS template with Next.js + Supabase.
# This refactored version separates module content from file-writing logic
# for easier maintenance and safer editing.

set -e

PROJECT_NAME=${1:-"lean-saas-app"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${PURPLE}🚀 $1${NC}"; }

# ==============================================================================
# HÀM NỘI DUNG MODULES: Nơi an toàn để bạn chỉnh sửa nội dung các script con.
# Mỗi hàm chỉ chịu trách nhiệm cho nội dung của MỘT file.
# ==============================================================================

print_module_01_content() {
cat << 'MODULE_EOF'
#!/bin/bash
# Module 1: Project Structure Setup

PROJECT_NAME=$1
log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_project_structure() {
    log_info "Creating project structure for $PROJECT_NAME..."
    
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    
    # Main directories (don't create frontend subdirectories yet)
    mkdir -p {supabase,shared,docs,.vscode,scripts}
    
    # Supabase subdirectories
    mkdir -p supabase/{functions,migrations,seed,policies}
    mkdir -p supabase/functions/{stripe-webhook,send-email,user-management}
    
    # Shared subdirectories
    mkdir -p shared/{types,utils,constants,schemas}
    
    log_success "Project structure created"
}

setup_project_structure $1
MODULE_EOF
}

print_module_02_content() {
cat << 'MODULE_EOF'
#!/bin/bash
# Module 2: Frontend Setup (Next.js + Dependencies) - FIXED

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_frontend() {
    log_info "Setting up Next.js frontend..."
    
    # Create frontend directory if it doesn't exist
    mkdir -p frontend
    cd frontend
    
    # Check if pnpm is installed
    if ! command -v pnpm &> /dev/null; then
        log_info "Installing pnpm..."
        npm install -g pnpm
    fi
    
    # Check if directory has files, if so clear it first
    if [ "$(ls -A .)" ]; then
        log_info "Clearing existing frontend files..."
        rm -rf ./* .* 2>/dev/null || true
    fi
    
    # Initialize Next.js project
    pnpm create next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --skip-install
    
    # Add SaaS-specific dependencies
    log_info "Adding SaaS dependencies..."
    
    # Core dependencies
    pnpm add @supabase/ssr @supabase/supabase-js
    pnpm add @stripe/stripe-js stripe
    pnpm add resend @react-email/components @react-email/render
    
    # UI Components (only valid Radix UI packages)
    pnpm add @radix-ui/react-dialog @radix-ui/react-dropdown-menu
    pnpm add @radix-ui/react-select @radix-ui/react-toast
    pnpm add @radix-ui/react-accordion @radix-ui/react-tabs
    pnpm add @radix-ui/react-avatar
    pnpm add lucide-react
    
    # Utilities
    pnpm add class-variance-authority clsx tailwind-merge
    pnpm add zod react-hook-form @hookform/resolvers
    pnpm add date-fns
    pnpm add next-themes
    pnpm add sonner # Better toast notifications
    
    # State Management
    pnpm add zustand
    
    # Development dependencies
    pnpm add -D @types/node prettier prettier-plugin-tailwindcss
    pnpm add -D @types/react @types/react-dom
    pnpm add -D tailwindcss-animate
    
    # Install all dependencies
    pnpm install
    
    cd ..
    log_success "Frontend setup completed"
}

setup_frontend
MODULE_EOF
}

print_module_03_content() {
cat << 'MODULE_EOF'
#!/bin/bash
# Module 3: Supabase Setup

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }

detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

install_supabase_cli() {
    if command -v supabase &> /dev/null; then
        log_success "Supabase CLI already installed"
        return 0
    fi
    
    local os=$(detect_os)
    log_info "Installing Supabase CLI for $os..."
    
    case $os in
        "macos")
            if command -v brew &> /dev/null; then
                brew install supabase/tap/supabase
            else
                log_warning "Homebrew not found. Installing manually..."
                ARCH=$(uname -m)
                if [[ "$ARCH" == "arm64" ]]; then
                    DOWNLOAD_URL="https://github.com/supabase/cli/releases/latest/download/supabase_darwin_arm64.tar.gz"
                else
                    DOWNLOAD_URL="https://github.com/supabase/cli/releases/latest/download/supabase_darwin_amd64.tar.gz"
                fi
                curl -L "$DOWNLOAD_URL" | tar -xz
                sudo mv supabase /usr/local/bin/
            fi
            ;;
        "linux")
            curl -L https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
            sudo mv supabase /usr/local/bin/
            ;;
        *)
            log_warning "Please install Supabase CLI manually: https://supabase.com/docs/guides/cli"
            ;;
    esac
}

setup_supabase() {
    log_info "Setting up Supabase..."
    
    install_supabase_cli
    
    cd supabase
    
    # Initialize Supabase
    supabase init
    
    # Create database schema
    create_database_schema
    
    # Create RLS policies
    create_rls_policies
    
    # Create edge functions
    create_edge_functions
    
    cd ..
    log_success "Supabase setup completed"
}

create_database_schema() {
    log_info "Creating database schema..."
    
    cat > migrations/001_initial_schema.sql << 'SQL'
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Profiles table
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    plan_type TEXT DEFAULT 'free' CHECK (plan_type IN ('free', 'pro', 'enterprise')),
    stripe_customer_id TEXT UNIQUE,
    onboarded BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Organizations/Teams table
CREATE TABLE public.organizations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    plan_type TEXT DEFAULT 'free' CHECK (plan_type IN ('free', 'pro', 'enterprise')),
    stripe_customer_id TEXT UNIQUE,
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Organization members
CREATE TABLE public.organization_members (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    invited_by UUID REFERENCES public.profiles(id),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(organization_id, user_id)
);

-- Subscriptions table
CREATE TABLE public.subscriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    stripe_subscription_id TEXT UNIQUE NOT NULL,
    stripe_price_id TEXT NOT NULL,
    status TEXT NOT NULL,
    current_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Projects/Items table (example for SaaS)
CREATE TABLE public.projects (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
    created_by UUID REFERENCES public.profiles(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_organizations_slug ON public.organizations(slug);
CREATE INDEX idx_organization_members_org_id ON public.organization_members(organization_id);
CREATE INDEX idx_organization_members_user_id ON public.organization_members(user_id);
CREATE INDEX idx_subscriptions_stripe_id ON public.subscriptions(stripe_subscription_id);
CREATE INDEX idx_projects_org_id ON public.projects(organization_id);

-- Update triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
SQL
}

create_rls_policies() {
    log_info "Creating RLS policies..."
    
    cat > migrations/002_rls_policies.sql << 'SQL'
-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Organizations policies
CREATE POLICY "Users can view organizations they're members of" ON public.organizations
    FOR SELECT USING (
        id IN (
            SELECT organization_id FROM public.organization_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Organization owners can update" ON public.organizations
    FOR UPDATE USING (owner_id = auth.uid());

-- Organization members policies
CREATE POLICY "Users can view organization members" ON public.organization_members
    FOR SELECT USING (
        organization_id IN (
            SELECT organization_id FROM public.organization_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Organization admins can manage members" ON public.organization_members
    FOR ALL USING (
        organization_id IN (
            SELECT organization_id FROM public.organization_members 
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- Projects policies
CREATE POLICY "Users can view organization projects" ON public.projects
    FOR SELECT USING (
        organization_id IN (
            SELECT organization_id FROM public.organization_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create projects in their organizations" ON public.projects
    FOR INSERT WITH CHECK (
        organization_id IN (
            SELECT organization_id FROM public.organization_members 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update projects in their organizations" ON public.projects
    FOR UPDATE USING (
        organization_id IN (
            SELECT organization_id FROM public.organization_members 
            WHERE user_id = auth.uid()
        )
    );
SQL
}

create_edge_functions() {
    log_info "Creating edge functions..."
    
    # Stripe webhook function
    mkdir -p functions/stripe-webhook
    cat > functions/stripe-webhook/index.ts << 'DENO'
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4'
import Stripe from 'https://esm.sh/stripe@16.12.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, stripe-signature',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const signature = req.headers.get('stripe-signature')
    const body = await req.text()
    
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
      apiVersion: '2023-10-16',
    })
    
    const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
    const event = stripe.webhooks.constructEvent(body, signature!, webhookSecret!)
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await handleSubscriptionUpdate(supabase, event.data.object)
        break
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(supabase, event.data.object)
        break
      default:
        console.log(`Unhandled event type: ${event.type}`)
    }
    
    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    })
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400
    })
  }
})

async function handleSubscriptionUpdate(supabase: any, subscription: any) {
  const { error } = await supabase
    .from('subscriptions')
    .upsert({
      stripe_subscription_id: subscription.id,
      stripe_price_id: subscription.items.data[0].price.id,
      status: subscription.status,
      current_period_start: new Date(subscription.current_period_start * 1000),
      current_period_end: new Date(subscription.current_period_end * 1000),
      cancel_at_period_end: subscription.cancel_at_period_end,
      updated_at: new Date()
    })
    
  if (error) {
    console.error('Error updating subscription:', error)
    throw error
  }
}

async function handleSubscriptionDeleted(supabase: any, subscription: any) {
  const { error } = await supabase
    .from('subscriptions')
    .update({
      status: 'canceled',
      updated_at: new Date()
    })
    .eq('stripe_subscription_id', subscription.id)
    
  if (error) {
    console.error('Error deleting subscription:', error)
    throw error
  }
}
DENO
}

setup_supabase
MODULE_EOF
}

print_module_04_content() {
cat << 'MODULE_EOF'
#!/bin/bash
# Module 4: Authentication System Setup

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_auth_system() {
    log_info "Setting up authentication system..."
    
    cd frontend/src
    
    # Create auth-related directories
    mkdir -p app/auth/{login,register,forgot-password,callback}
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

setup_auth_system
MODULE_EOF
}

print_module_05_content() {
cat << 'MODULE_EOF'
#!/bin/bash
# Module 5: UI Components Setup

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_ui_components() {
    log_info "Setting up UI components..."
    
    # Navigate to src directory first
    cd frontend/src
    
    # Create components directory and navigate into it
    mkdir -p components
    cd components
    
    # Create component directories
    mkdir -p {ui,auth,layouts,features,forms}
    
    create_base_ui_components
    create_auth_components
    create_layout_components
    create_form_components
    
    cd ../../..
    log_success "UI components setup completed"
}

create_base_ui_components() {
    log_info "Creating base UI components..."
    
    # Create utils.ts in lib directory first
    mkdir -p ../lib
    cat > ../lib/utils.ts << 'TS'
// lib/utils.ts
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(input: string | number | Date): string {
  const date = new Date(input)
  return date.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  })
}

export function formatCurrency(
  amount: number,
  currency: string = 'USD'
): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
  }).format(amount)
}
TS
    
    # Button component
    cat > ui/Button.tsx << 'TSX'
// ui/Button.tsx
import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'underline-offset-4 hover:underline text-primary',
      },
      size: {
        default: 'h-10 py-2 px-4',
        sm: 'h-9 px-3 rounded-md',
        lg: 'h-11 px-8 rounded-md',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = 'Button'

export { Button, buttonVariants }
TSX

    # Input component
    cat > ui/Input.tsx << 'TSX'
// ui/Input.tsx
import * as React from 'react'
import { cn } from '@/lib/utils'

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = 'Input'

export { Input }
TSX

    # Label component
    cat > ui/Label.tsx << 'TSX'
// ui/Label.tsx
import * as React from 'react'
import { cn } from '@/lib/utils'

export interface LabelProps
  extends React.LabelHTMLAttributes<HTMLLabelElement> {}

const Label = React.forwardRef<HTMLLabelElement, LabelProps>(
  ({ className, ...props }, ref) => (
    <label
      ref={ref}
      className={cn(
        'text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70',
        className
      )}
      {...props}
    />
  )
)
Label.displayName = 'Label'

export { Label }
TSX
}

create_auth_components() {
    log_info "Creating auth components..."
    
    cat > auth/LoginForm.tsx << 'TSX'
// auth/LoginForm.tsx
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Label } from '@/components/ui/Label'
import { useRouter } from 'next/navigation'
import { authConfig } from '@/lib/auth/config'

export function LoginForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const router = useRouter()
  const supabase = createClient()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) {
        setError(error.message)
      } else {
        router.push(authConfig.signIn.redirectTo)
      }
    } catch (err) {
      setError('An unexpected error occurred')
    } finally {
      setLoading(false)
    }
  }

  const handleGoogleSignIn = async () => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    })

    if (error) {
      setError(error.message)
    }
  }

  return (
    <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
          {error}
        </div>
      )}
      
      <div className="space-y-4">
        <div>
          <Label htmlFor="email">Email address</Label>
          <Input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="mt-1"
          />
        </div>
        
        <div>
          <Label htmlFor="password">Password</Label>
          <Input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="mt-1"
          />
        </div>
      </div>

      <div className="flex items-center justify-between">
        <div className="text-sm">
          <a
            href="/auth/forgot-password"
            className="font-medium text-indigo-600 hover:text-indigo-500"
          >
            Forgot your password?
          </a>
        </div>
      </div>

      <div className="space-y-3">
        <Button
          type="submit"
          className="w-full"
          disabled={loading}
        >
          {loading ? 'Signing in...' : 'Sign in'}
        </Button>
        
        <Button
          type="button"
          variant="outline"
          className="w-full"
          onClick={handleGoogleSignIn}
        >
          Sign in with Google
        </Button>
      </div>
    </form>
  )
}
TSX

    cat > auth/RegisterForm.tsx << 'TSX'
// auth/RegisterForm.tsx
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Label } from '@/components/ui/Label'
import { authConfig } from '@/lib/auth/config'

export function RegisterForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [fullName, setFullName] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)
  const supabase = createClient()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName,
          },
          emailRedirectTo: `${window.location.origin}${authConfig.signUp.redirectTo}`,
        },
      })

      if (error) {
        setError(error.message)
      } else {
        setSuccess(true)
      }
    } catch (err) {
      setError('An unexpected error occurred')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="bg-green-50 border border-green-200 text-green-600 px-4 py-3 rounded">
        <p>Please check your email to confirm your account.</p>
      </div>
    )
  }

  return (
    <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
          {error}
        </div>
      )}
      
      <div className="space-y-4">
        <div>
          <Label htmlFor="fullName">Full name</Label>
          <Input
            id="fullName"
            name="fullName"
            type="text"
            autoComplete="name"
            required
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            className="mt-1"
          />
        </div>
        
        <div>
          <Label htmlFor="email">Email address</Label>
          <Input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="mt-1"
          />
        </div>
        
        <div>
          <Label htmlFor="password">Password</Label>
          <Input
            id="password"
            name="password"
            type="password"
            autoComplete="new-password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="mt-1"
          />
        </div>
      </div>

      <Button
        type="submit"
        className="w-full"
        disabled={loading}
      >
        {loading ? 'Creating account...' : 'Create account'}
      </Button>
    </form>
  )
}
TSX
}

create_layout_components() {
    log_info "Creating layout components..."
    
    cat > layouts/DashboardLayout.tsx << 'TSX'
// layouts/DashboardLayout.tsx
'use client'

import { useAuth } from '@/hooks/auth/useAuth'
import { Button } from '@/components/ui/Button'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'

interface DashboardLayoutProps {
  children: React.ReactNode
}

const navigation = [
  { name: 'Dashboard', href: '/dashboard' },
  { name: 'Projects', href: '/dashboard/projects' },
  { name: 'Settings', href: '/dashboard/settings' },
  { name: 'Billing', href: '/dashboard/billing' },
]

export function DashboardLayout({ children }: DashboardLayoutProps) {
  const { user, signOut } = useAuth()
  const pathname = usePathname()

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex">
              <div className="flex-shrink-0 flex items-center">
                <h1 className="text-xl font-bold">SaaS App</h1>
              </div>
              <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                {navigation.map((item) => (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={cn(
                      'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm',
                      pathname === item.href && 'border-indigo-500 text-gray-900'
                    )}
                  >
                    {item.name}
                  </Link>
                ))}
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-700">{user?.email}</span>
              <Button variant="outline" onClick={signOut}>
                Sign out
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Main content */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  )
}
TSX
}

create_form_components() {
    log_info "Creating form components..."
    
    cat > forms/ContactForm.tsx << 'TSX'
// forms/ContactForm.tsx
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Label } from '@/components/ui/Label'

export function ContactForm() {
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    const formData = new FormData(e.currentTarget)
    
    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        body: formData,
      })

      if (response.ok) {
        setSuccess(true)
        e.currentTarget.reset()
      } else {
        setError('Failed to send message')
      }
    } catch (err) {
      setError('An unexpected error occurred')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="bg-green-50 border border-green-200 text-green-600 px-4 py-3 rounded">
        <p>Thank you for your message! We'll get back to you soon.</p>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
          {error}
        </div>
      )}
      
      <div>
        <Label htmlFor="name">Name</Label>
        <Input
          id="name"
          name="name"
          type="text"
          required
          className="mt-1"
        />
      </div>
      
      <div>
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          name="email"
          type="email"
          required
          className="mt-1"
        />
      </div>
      
      <div>
        <Label htmlFor="message">Message</Label>
        <textarea
          id="message"
          name="message"
          rows={4}
          required
          className="mt-1 flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        />
      </div>
      
      <Button type="submit" disabled={loading}>
        {loading ? 'Sending...' : 'Send Message'}
      </Button>
    </form>
  )
}
TSX
}

setup_ui_components
MODULE_EOF
}

print_module_06_content() {
cat << 'MODULE_EOF'
#!/bin/bash
# Module 6: Payment System Setup

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_payment_system() {
    log_info "Setting up payment system..."
    
    cd frontend/src
    
    # Create payment-related directories
    mkdir -p {lib/stripe,hooks/billing,app/api/stripe,app/dashboard/billing}
    
    create_stripe_config
    create_billing_hooks
    create_stripe_api_routes
    create_billing_pages
    
    cd ../..
    log_success "Payment system setup completed"
}

create_stripe_config() {
    log_info "Creating Stripe configuration..."
    
    cat > lib/stripe/config.ts << 'TS'
// lib/stripe/config.ts
export const PLANS = {
  free: {
    name: 'Free',
    description: 'Perfect for getting started',
    price: 0,
    priceId: '',
    features: [
      'Up to 3 projects',
      'Basic support',
      '1GB storage',
    ],
  },
  pro: {
    name: 'Pro',
    description: 'For growing businesses',
    price: 19,
    priceId: process.env.STRIPE_PRO_PRICE_ID!,
    features: [
      'Unlimited projects',
      'Priority support',
      '100GB storage',
      'Advanced analytics',
    ],
  },
  enterprise: {
    name: 'Enterprise',
    description: 'For large organizations',
    price: 99,
    priceId: process.env.STRIPE_ENTERPRISE_PRICE_ID!,
    features: [
      'Everything in Pro',
      'Custom integrations',
      'Dedicated support',
      'SLA guarantee',
    ],
  },
} as const

export type PlanType = keyof typeof PLANS
TS

    cat > lib/stripe/client.ts << 'TS'
// lib/stripe/client.ts
import { loadStripe } from '@stripe/stripe-js'

export const getStripe = () => {
  return loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!)
}

export const redirectToCheckout = async (priceId: string) => {
  const stripe = await getStripe()
  
  const { error } = await stripe!.redirectToCheckout({
    lineItems: [{ price: priceId, quantity: 1 }],
    mode: 'subscription',
    successUrl: `${window.location.origin}/dashboard/billing?success=true`,
    cancelUrl: `${window.location.origin}/dashboard/billing?canceled=true`,
  })
  
  if (error) {
    console.error('Stripe error:', error)
    throw error
  }
}
TS

    cat > lib/stripe/server.ts << 'TS'
// lib/stripe/server.ts
import Stripe from 'stripe'

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error('STRIPE_SECRET_KEY is not set')
}

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2023-10-16',
})

export const createCustomer = async (email: string, name?: string) => {
  return await stripe.customers.create({
    email,
    name,
  })
}

export const createCheckoutSession = async (
  customerId: string,
  priceId: string,
  successUrl: string,
  cancelUrl: string
) => {
  return await stripe.checkout.sessions.create({
    customer: customerId,
    payment_method_types: ['card'],
    line_items: [
      {
        price: priceId,
        quantity: 1,
      },
    ],
    mode: 'subscription',
    success_url: successUrl,
    cancel_url: cancelUrl,
  })
}

export const createPortalSession = async (
  customerId: string,
  returnUrl: string
) => {
  return await stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: returnUrl,
  })
}

export const getSubscription = async (subscriptionId: string) => {
  return await stripe.subscriptions.retrieve(subscriptionId)
}
TS
}

create_billing_hooks() {
    log_info "Creating billing hooks..."
    
    cat > hooks/billing/useSubscription.ts << 'TS'
// hooks/billing/useSubscription.ts
'use client'

import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/hooks/auth/useAuth'
import { useEffect, useState } from 'react'

interface Subscription {
  id: string
  stripe_subscription_id: string
  stripe_price_id: string
  status: string
  current_period_start: string
  current_period_end: string
  cancel_at_period_end: boolean
}

export function useSubscription() {
  const { user } = useAuth()
  const [subscription, setSubscription] = useState<Subscription | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const supabase = createClient()
  
  useEffect(() => {
    if (!user) {
      setLoading(false)
      return
    }
    
    const fetchSubscription = async () => {
      try {
        setLoading(true)
        const { data, error } = await supabase
          .from('subscriptions')
          .select('*')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .single()
          
        if (error && error.code !== 'PGRST116') {
          setError(error.message)
        } else {
          setSubscription(data)
        }
      } catch (err) {
        setError('Failed to fetch subscription')
      } finally {
        setLoading(false)
      }
    }
    
    fetchSubscription()
  }, [user, supabase])
  
  const createCheckoutSession = async (priceId: string) => {
    try {
      const response = await fetch('/api/stripe/checkout', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ priceId }),
      })
      
      const { url } = await response.json()
      
      if (url) {
        window.location.href = url
      }
    } catch (err) {
      console.error('Error creating checkout session:', err)
      throw err
    }
  }
  
  const createPortalSession = async () => {
    try {
      const response = await fetch('/api/stripe/portal', {
        method: 'POST',
      })
      
      const { url } = await response.json()
      
      if (url) {
        window.location.href = url
      }
    } catch (err) {
      console.error('Error creating portal session:', err)
      throw err
    }
  }
  
  return {
    subscription,
    loading,
    error,
    createCheckoutSession,
    createPortalSession,
  }
}
TS
}

create_stripe_api_routes() {
    log_info "Creating Stripe API routes..."
    
    # Create necessary directories first
    mkdir -p app/api/stripe/{checkout,portal}
    
    # Checkout API route
    cat > app/api/stripe/checkout/route.ts << 'TS'
// app/api/stripe/checkout/route.ts
import { createAuthClient } from '@/lib/auth/server'
import { stripe, createCheckoutSession } from '@/lib/stripe/server'
import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const supabase = await createAuthClient()
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }
    
    const { priceId } = await request.json()
    
    if (!priceId) {
      return NextResponse.json({ error: 'Price ID is required' }, { status: 400 })
    }
    
    // Get or create customer
    const { data: profile } = await supabase
      .from('profiles')
      .select('stripe_customer_id, email, full_name')
      .eq('id', user.id)
      .single()
    
    let customerId = profile?.stripe_customer_id
    
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: profile?.email || user.email!,
        name: profile?.full_name || undefined,
        metadata: {
          userId: user.id,
        },
      })
      
      customerId = customer.id
      
      // Update profile with customer ID
      await supabase
        .from('profiles')
        .update({ stripe_customer_id: customerId })
        .eq('id', user.id)
    }
    
    const session = await createCheckoutSession(
      customerId,
      priceId,
      `${request.nextUrl.origin}/dashboard/billing?success=true`,
      `${request.nextUrl.origin}/dashboard/billing?canceled=true`
    )
    
    return NextResponse.json({ url: session.url })
  } catch (error) {
    console.error('Checkout error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
TS

    # Portal API route
    cat > app/api/stripe/portal/route.ts << 'TS'
// app/api/stripe/portal/route.ts
import { createAuthClient } from '@/lib/auth/server'
import { createPortalSession } from '@/lib/stripe/server'
import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const supabase = await createAuthClient()
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }
    
    const { data: profile } = await supabase
      .from('profiles')
      .select('stripe_customer_id')
      .eq('id', user.id)
      .single()
    
    if (!profile?.stripe_customer_id) {
      return NextResponse.json(
        { error: 'No customer found' },
        { status: 400 }
      )
    }
    
    const session = await createPortalSession(
      profile.stripe_customer_id,
      `${request.nextUrl.origin}/dashboard/billing`
    )
    
    return NextResponse.json({ url: session.url })
  } catch (error) {
    console.error('Portal error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
TS
}

create_billing_pages() {
    log_info "Creating billing pages..."
    
    cat > app/dashboard/billing/page.tsx << 'TSX'
// app/dashboard/billing/page.tsx
'use client'

import { useSubscription } from '@/hooks/billing/useSubscription'
import { PLANS } from '@/lib/stripe/config'
import { Button } from '@/components/ui/Button'
import { DashboardLayout } from '@/components/layouts/DashboardLayout'

export default function BillingPage() {
  const { subscription, loading, createCheckoutSession, createPortalSession } = useSubscription()
  
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
        <h1 className="text-2xl font-bold mb-6">Billing & Subscription</h1>
        
        {subscription ? (
          <div className="bg-white p-6 rounded-lg shadow mb-6">
            <h2 className="text-lg font-semibold mb-4">Current Subscription</h2>
            <p className="text-gray-600 mb-4">
              Status: <span className="font-medium capitalize">{subscription.status}</span>
            </p>
            <p className="text-gray-600 mb-4">
              Current period ends: {new Date(subscription.current_period_end).toLocaleDateString()}
            </p>
            <Button onClick={createPortalSession}>
              Manage Subscription
            </Button>
          </div>
        ) : (
          <div className="bg-white p-6 rounded-lg shadow mb-6">
            <h2 className="text-lg font-semibold mb-4">No Active Subscription</h2>
            <p className="text-gray-600 mb-4">
              Choose a plan to get started with premium features.
            </p>
          </div>
        )}
        
        <div className="grid md:grid-cols-3 gap-6">
          {Object.entries(PLANS).map(([key, plan]) => (
            <div
              key={key}
              className="bg-white p-6 rounded-lg shadow border"
            >
              <h3 className="text-xl font-semibold mb-2">{plan.name}</h3>
              <p className="text-gray-600 mb-4">{plan.description}</p>
              <div className="text-3xl font-bold mb-4">
                ${plan.price}
                {plan.price > 0 && <span className="text-lg text-gray-600">/month</span>}
              </div>
              <ul className="space-y-2 mb-6">
                {plan.features.map((feature, index) => (
                  <li key={index} className="flex items-center">
                    <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                    {feature}
                  </li>
                ))}
              </ul>
              {plan.price > 0 && (
                <Button
                  className="w-full"
                  onClick={() => createCheckoutSession(plan.priceId)}
                  disabled={!plan.priceId}
                >
                  Subscribe
                </Button>
              )}
              {plan.price === 0 && (
                <Button variant="outline" className="w-full" disabled>
                  Current Plan
                </Button>
              )}
            </div>
          ))}
        </div>
      </div>
    </DashboardLayout>
  )
}
TSX
}

setup_payment_system
MODULE_EOF
}

print_module_07_content() {
cat << 'MODULE_EOF'
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
MODULE_EOF
}

print_module_08_content() {
cat << 'MODULE_EOF'
#!/bin/bash
# Module 8: Email System Setup

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_email_system() {
    log_info "Setting up email system..."
    
    cd frontend/src
    
    # Create email-related directories
    mkdir -p {lib/email,emails,app/api/send-email}
    
    create_email_config
    create_email_templates
    create_email_api_routes
    
    cd ../..
    log_success "Email system setup completed"
}

create_email_config() {
    log_info "Creating email configuration..."
    
    cat > lib/email/config.ts << 'TS'
// lib/email/config.ts
import { Resend } from 'resend'

if (!process.env.RESEND_API_KEY) {
  throw new Error('RESEND_API_KEY is not set')
}

export const resend = new Resend(process.env.RESEND_API_KEY)

export const emailConfig = {
  from: 'noreply@yourdomain.com',
  replyTo: 'support@yourdomain.com',
  subjects: {
    welcome: 'Welcome to SaaS App!',
    passwordReset: 'Reset your password',
    emailVerification: 'Verify your email address',
    subscriptionConfirmation: 'Subscription confirmed',
    subscriptionCanceled: 'Subscription canceled',
  },
}
TS

    cat > lib/email/utils.ts << 'TS'
// lib/email/utils.ts
import { resend, emailConfig } from './config'
import { WelcomeEmail } from '@/emails/WelcomeEmail'
import { PasswordResetEmail } from '@/emails/PasswordResetEmail'

export interface SendEmailOptions {
  to: string
  subject: string
  react: React.ReactElement
}

export const sendEmail = async ({ to, subject, react }: SendEmailOptions) => {
  try {
    const { data, error } = await resend.emails.send({
      from: emailConfig.from,
      to,
      subject,
      react,
    })

    if (error) {
      console.error('Email sending error:', error)
      throw error
    }

    return data
  } catch (error) {
    console.error('Failed to send email:', error)
    throw error
  }
}

export const sendWelcomeEmail = async (to: string, name: string) => {
  return sendEmail({
    to,
    subject: emailConfig.subjects.welcome,
    react: WelcomeEmail({ name }),
  })
}

export const sendPasswordResetEmail = async (to: string, resetUrl: string) => {
  return sendEmail({
    to,
    subject: emailConfig.subjects.passwordReset,
    react: PasswordResetEmail({ resetUrl }),
  })
}
TS
}

create_email_templates() {
    log_info "Creating email templates..."
    
    cat > emails/WelcomeEmail.tsx << 'TSX'
// emails/WelcomeEmail.tsx
import {
  Body,
  Button,
  Container,
  Head,
  Hr,
  Html,
  Img,
  Preview,
  Section,
  Text,
} from '@react-email/components'
import * as React from 'react'

interface WelcomeEmailProps {
  name: string
}

export const WelcomeEmail = ({ name }: WelcomeEmailProps) => (
  <Html>
    <Head />
    <Preview>Welcome to SaaS App - Get started today!</Preview>
    <Body style={main}>
      <Container style={container}>
        <Section style={logoContainer}>
          <Text style={logo}>SaaS App</Text>
        </Section>
        <Text style={paragraph}>Hi {name},</Text>
        <Text style={paragraph}>
          Welcome to SaaS App! We're excited to have you on board.
        </Text>
        <Text style={paragraph}>
          Your account has been successfully created. You can now start using all the features
          available in your plan.
        </Text>
        <Section style={btnContainer}>
          <Button style={button} href={`${process.env.NEXT_PUBLIC_APP_URL}/dashboard`}>
            Get Started
          </Button>
        </Section>
        <Text style={paragraph}>
          If you have any questions, feel free to reach out to our support team.
        </Text>
        <Text style={paragraph}>
          Best regards,<br />
          The SaaS App Team
        </Text>
        <Hr style={hr} />
        <Text style={footer}>
          If you didn't create this account, you can safely ignore this email.
        </Text>
      </Container>
    </Body>
  </Html>
)

const main = {
  backgroundColor: '#ffffff',
  fontFamily:
    '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif',
}

const container = {
  margin: '0 auto',
  padding: '20px 0 48px',
}

const logoContainer = {
  textAlign: 'center' as const,
}

const logo = {
  fontSize: '32px',
  fontWeight: 'bold',
  color: '#1f2937',
}

const paragraph = {
  fontSize: '16px',
  lineHeight: '26px',
}

const btnContainer = {
  textAlign: 'center' as const,
}

const button = {
  backgroundColor: '#5F51E8',
  borderRadius: '3px',
  color: '#fff',
  fontSize: '16px',
  textDecoration: 'none',
  textAlign: 'center' as const,
  display: 'block',
  padding: '12px',
}

const hr = {
  borderColor: '#cccccc',
  margin: '20px 0',
}

const footer = {
  color: '#8898aa',
  fontSize: '12px',
}
TSX

    cat > emails/PasswordResetEmail.tsx << 'TSX'
// emails/PasswordResetEmail.tsx
import {
  Body,
  Button,
  Container,
  Head,
  Hr,
  Html,
  Preview,
  Section,
  Text,
} from '@react-email/components'
import * as React from 'react'

interface PasswordResetEmailProps {
  resetUrl: string
}

export const PasswordResetEmail = ({ resetUrl }: PasswordResetEmailProps) => (
  <Html>
    <Head />
    <Preview>Reset your SaaS App password</Preview>
    <Body style={main}>
      <Container style={container}>
        <Section style={logoContainer}>
          <Text style={logo}>SaaS App</Text>
        </Section>
        <Text style={paragraph}>Hi there,</Text>
        <Text style={paragraph}>
          We received a request to reset your password for your SaaS App account.
        </Text>
        <Text style={paragraph}>
          Click the button below to reset your password. This link will expire in 1 hour.
        </Text>
        <Section style={btnContainer}>
          <Button style={button} href={resetUrl}>
            Reset Password
          </Button>
        </Section>
        <Text style={paragraph}>
          If you didn't request this password reset, you can safely ignore this email.
          Your password will remain unchanged.
        </Text>
        <Text style={paragraph}>
          Best regards,<br />
          The SaaS App Team
        </Text>
        <Hr style={hr} />
        <Text style={footer}>
          If the button doesn't work, copy and paste this link into your browser:<br />
          {resetUrl}
        </Text>
      </Container>
    </Body>
  </Html>
)

const main = {
  backgroundColor: '#ffffff',
  fontFamily:
    '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif',
}

const container = {
  margin: '0 auto',
  padding: '20px 0 48px',
}

const logoContainer = {
  textAlign: 'center' as const,
}

const logo = {
  fontSize: '32px',
  fontWeight: 'bold',
  color: '#1f2937',
}

const paragraph = {
  fontSize: '16px',
  lineHeight: '26px',
}

const btnContainer = {
  textAlign: 'center' as const,
}

const button = {
  backgroundColor: '#5F51E8',
  borderRadius: '3px',
  color: '#fff',
  fontSize: '16px',
  textDecoration: 'none',
  textAlign: 'center' as const,
  display: 'block',
  padding: '12px',
}

const hr = {
  borderColor: '#cccccc',
  margin: '20px 0',
}

const footer = {
  color: '#8898aa',
  fontSize: '12px',
}
TSX
}

create_email_api_routes() {
    log_info "Creating email API routes..."
    
    # Create necessary directories first
    mkdir -p app/api/send-email
    
    cat > app/api/send-email/route.ts << 'TS'
// app/api/send-email/route.ts
import { createAuthClient } from '@/lib/auth/server'
import { sendWelcomeEmail } from '@/lib/email/utils'
import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const supabase = await createAuthClient()
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }
    
    const { type, to, data } = await request.json()
    
    switch (type) {
      case 'welcome':
        await sendWelcomeEmail(to, data.name)
        break
      default:
        return NextResponse.json({ error: 'Invalid email type' }, { status: 400 })
    }
    
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Email API error:', error)
    return NextResponse.json(
      { error: 'Failed to send email' },
      { status: 500 }
    )
  }
}
TS
}

setup_email_system
MODULE_EOF
}

print_module_09_content() {
cat << 'MODULE_EOF'
#!/bin/bash
# Module 9: Development Tools Setup

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_dev_tools() {
    log_info "Setting up development tools..."
    
    cd frontend
    
    # Add testing and dev dependencies
    pnpm add -D @testing-library/react @testing-library/jest-dom @testing-library/user-event
    pnpm add -D jest jest-environment-jsdom
    pnpm add -D eslint-config-prettier
    pnpm add -D husky lint-staged
    
    create_testing_config
    create_git_hooks
    create_github_workflows
    create_docker_config
    
    cd ..
    log_success "Development tools setup completed"
}

create_testing_config() {
    log_info "Creating testing configuration..."
    
    cat > jest.config.js << 'JS'
// jest.config.js
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  dir: './',
})

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  moduleNameMapping: {
    '^@/components/(.*)$': '<rootDir>/src/components/$1',
    '^@/lib/(.*)$': '<rootDir>/src/lib/$1',
    '^@/hooks/(.*)$': '<rootDir>/src/hooks/$1',
    '^@/shared/(.*)$': '<rootDir>/../shared/$1',
  },
  testEnvironment: 'jest-environment-jsdom',
}

module.exports = createJestConfig(customJestConfig)
JS

    cat > jest.setup.js << 'JS'
// jest.setup.js
import '@testing-library/jest-dom'
JS

    # Create __tests__ directory first
    mkdir -p __tests__
    cat > __tests__/example.test.tsx << 'TSX'
// __tests__/example.test.tsx
import { render, screen } from '@testing-library/react'
import { Button } from '@/components/ui/Button'

describe('Button', () => {
  it('renders a button', () => {
    render(<Button>Click me</Button>)
    const button = screen.getByRole('button', { name: /click me/i })
    expect(button).toBeInTheDocument()
  })
})
TSX

    # Update package.json scripts
    cat > package.json.tmp << 'JSON'
{
  "scripts": {
    "dev": "next dev",
    "build": "next build", 
    "start": "next start",
    "lint": "next lint",
    "lint:fix": "next lint --fix",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "type-check": "tsc --noEmit",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  }
}
JSON
    
    # Merge with existing package.json (simplified approach)
    if [ -f package.json ]; then
        node -e "
            const fs = require('fs');
            const existing = JSON.parse(fs.readFileSync('package.json', 'utf8'));
            const newScripts = JSON.parse(fs.readFileSync('package.json.tmp', 'utf8')).scripts;
            existing.scripts = { ...existing.scripts, ...newScripts };
            fs.writeFileSync('package.json', JSON.stringify(existing, null, 2));
        "
    fi
    rm -f package.json.tmp
}

create_git_hooks() {
    log_info "Creating Git hooks..."
    
    cat > .lintstagedrc.json << 'JSON'
{
  "*.{js,jsx,ts,tsx}": [
    "eslint --fix",
    "prettier --write"
  ],
  "*.{json,md,css}": [
    "prettier --write"
  ]
}
JSON

    # Initialize husky first
    npx husky init
    
    # Create pre-commit hook
    cat > .husky/pre-commit << 'HOOK'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged
HOOK

    chmod +x .husky/pre-commit
}

create_github_workflows() {
    log_info "Creating GitHub workflows..."
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/ci.yml << 'YAML'
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [18.x, 20.x]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          
      - uses: pnpm/action-setup@v2
        with:
          version: 8
          
      - name: Get pnpm store directory
        shell: bash
        run: |
          echo "STORE_PATH=$(pnpm store path --silent)" >> $GITHUB_ENV
          
      - uses: actions/cache@v3
        name: Setup pnpm cache
        with:
          path: ${{ env.STORE_PATH }}
          key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
          restore-keys: |
            ${{ runner.os }}-pnpm-store-
            
      - name: Install dependencies
        run: pnpm install --frozen-lockfile
        
      - name: Run type check
        run: pnpm type-check
        
      - name: Run linter
        run: pnpm lint
        
      - name: Run tests
        run: pnpm test --coverage
        
      - name: Build application
        run: pnpm build

  supabase:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: supabase/setup-cli@v1
        with:
          version: latest
          
      - name: Validate database schema
        run: |
          cd supabase
          supabase db diff --check
YAML

    cat > .github/workflows/deploy.yml << 'YAML'
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Use Node.js 20.x
        uses: actions/setup-node@v4
        with:
          node-version: 20.x
          
      - uses: pnpm/action-setup@v2
        with:
          version: 8
          
      - name: Install dependencies
        run: pnpm install --frozen-lockfile
        
      - name: Build application
        run: pnpm build
        
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
          vercel-args: '--prod'
YAML
}

create_docker_config() {
    log_info "Creating Docker configuration..."
    
    cat > Dockerfile << 'DOCKER'
# Dockerfile
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Install dependencies based on the preferred package manager
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm install -g pnpm
RUN pnpm build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
DOCKER

    cat > .dockerignore << 'IGNORE'
# .dockerignore
Dockerfile
.dockerignore
node_modules
npm-debug.log
README.md
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.git
.gitignore
.next
.vercel
coverage
__tests__
*.test.js
*.test.ts
*.test.tsx
IGNORE

    cat > docker-compose.yml << 'COMPOSE'
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: saas_app
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
COMPOSE
}

setup_dev_tools
MODULE_EOF
}


# ==============================================================================
# HÀM ĐIỀU PHỐI: Logic để ghi các module ra file.
# Bạn hầu như không cần sửa hàm này.
# ==============================================================================

write_module() {
    local module_number=$1
    local module_name=$2
    local filename="${module_number}-${module_name}.sh"

    log_info "Creating module script: $filename"

    # Dùng case statement để gọi hàm nội dung tương ứng và ghi ra file
    case $module_number in
        "01") print_module_01_content > "$filename" ;;
        "02") print_module_02_content > "$filename" ;;
        "03") print_module_03_content > "$filename" ;;
        "04") print_module_04_content > "$filename" ;;
        "05") print_module_05_content > "$filename" ;;
        "06") print_module_06_content > "$filename" ;;
        "07") print_module_07_content > "$filename" ;;
        "08") print_module_08_content > "$filename" ;;
        "09") print_module_09_content > "$filename" ;;
        *)
            log_error "Unknown module number: $module_number"
            return 1
            ;;
    esac

    # Cấp quyền thực thi cho file vừa tạo
    chmod +x "$filename"
}


# ==============================================================================
# LOGIC THỰC THI CHÍNH
# ==============================================================================

# Check dependencies
check_dependencies() {
    log_step "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v node &> /dev/null; then
        missing_deps+=("Node.js")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("Git")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install them and try again."
        exit 1
    fi
    
    log_success "All dependencies satisfied"
}

# Create project README
create_project_readme() {
    log_info "Creating project README..."
    
    cat > README.md << 'README'
# 🚀 Lean SaaS Template

A production-ready SaaS template built with Next.js 14, Supabase, and Stripe. Optimized for indie hackers and small teams.

## ✨ Features

### 🔐 Authentication & Authorization
- Email/password authentication
- OAuth providers (Google, GitHub)
- Row Level Security (RLS) policies
- Protected routes and middleware

### 💳 Payment & Billing
- Stripe integration for subscriptions
- Multiple pricing tiers
- Customer portal for billing management
- Webhook handling for events

### 📧 Email System
- Transactional emails with Resend
- React Email templates
- Welcome emails, password resets

### 🎨 UI/UX
- Tailwind CSS styling
- Radix UI components
- Responsive design
- Dark mode support

### 🛠️ Developer Experience
- TypeScript throughout
- ESLint + Prettier
- Testing with Jest
- CI/CD with GitHub Actions
- Docker support

## 🏗️ Architecture

```
├── frontend/         # Next.js 14 app
│   ├── src/app/        # App router pages
│   ├── src/components/ # Reusable components
│   ├── src/lib/        # Utilities and config
│   └── src/hooks/      # Custom React hooks
├── supabase/         # Database and functions
│   ├── migrations/     # Database schema
│   ├── functions/      # Edge functions
│   └── policies/       # RLS policies
└── shared/           # Shared types and utils
```

## 🚀 Quick Start

1. **Environment Setup**
   ```bash
   cp frontend/.env.local.example frontend/.env.local
   # Fill in your API keys
   ```

2. **Install Dependencies**
   ```bash
   cd frontend && pnpm install
   ```

3. **Start Supabase**
   ```bash
   cd supabase && supabase start
   ```

4. **Run Development Server**
   ```bash
   cd frontend && pnpm dev
   ```

## 📋 Environment Variables

### Frontend (.env.local)
```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRO_PRICE_ID=price_...
STRIPE_ENTERPRISE_PRICE_ID=price_...

# Resend
RESEND_API_KEY=re_...

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## 🗄️ Database Schema

### Core Tables
- `profiles` - User profiles and preferences
- `organizations` - Team/organization data
- `organization_members` - Team membership
- `subscriptions` - Stripe subscription data
- `projects` - Your app's core data

### Security
- Row Level Security (RLS) enabled
- Policies for multi-tenant access
- Secure by default

## 💰 Cost Optimization

- **80% Direct Supabase calls** - Leverage free tier
- **20% Edge Functions** - Only for webhooks/heavy logic
- **Pay-per-use APIs** - Stripe, Resend scale with usage

## 🧪 Testing

```bash
# Run tests
pnpm test

# Run with coverage
pnpm test:coverage

# Watch mode
pnpm test:watch
```

## 🚢 Deployment

### Vercel (Recommended)
1. Connect your GitHub repo
2. Set environment variables
3. Deploy automatically on push

### Docker
```bash
docker build -t saas-app .
docker run -p 3000:3000 saas-app
```

## 📚 Documentation

- [Development Guide](./docs/development.md)
- [Deployment Guide](./docs/deployment.md)
- [API Reference](./docs/api.md)
- [Troubleshooting](./docs/troubleshooting.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built with amazing open-source tools:
- [Next.js](https://nextjs.org/)
- [Supabase](https://supabase.com/)
- [Stripe](https://stripe.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Radix UI](https://www.radix-ui.com/)

---

## 📈 What's Included

### ✅ Authentication System
- [x] Login/Register pages
- [x] OAuth integration
- [x] Protected routes
- [x] User profiles

### ✅ Payment System
- [x] Stripe checkout
- [x] Subscription management
- [x] Webhook handling
- [x] Customer portal

### ✅ Dashboard
- [x] User dashboard
- [x] Project management
- [x] Settings pages
- [x] Billing page

### ✅ Email System
- [x] Welcome emails
- [x] Password reset
- [x] React Email templates

### ✅ Development Tools
- [x] TypeScript setup
- [x] Testing framework
- [x] CI/CD pipelines
- [x] Docker support

Ready to build your SaaS? 🚀
README
    log_success "Project README created"
}

# Create environment files
create_environment_files() {
    log_info "Creating environment files..."
    
    # Frontend environment
    cat > frontend/.env.local.example << 'ENV'
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Stripe Configuration
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
STRIPE_PRO_PRICE_ID=price_your_pro_price_id
STRIPE_ENTERPRISE_PRICE_ID=price_your_enterprise_price_id

# Resend Configuration
RESEND_API_KEY=re_your_resend_api_key

# Application Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
ENV

    # Development environment
    cat > .env.example << 'ENV'
# Development Environment Variables
PROJECT_NAME=lean-saas-app
NODE_ENV=development

# Database (for local development)
DATABASE_URL=postgresql://postgres:password@localhost:5432/saas_app

# Redis (for caching)
REDIS_URL=redis://localhost:6379

# Monitoring
SENTRY_DSN=your_sentry_dsn_if_using
ENV
}

# Create final documentation
create_final_documentation() {
    log_info "Creating final documentation..."
    
    mkdir -p docs
    
    # Development guide
    cat > docs/development.md << 'GUIDE'
# Development Guide

## Project Structure

### Frontend (Next.js 14)
```
frontend/src/
├── app/                  # App router pages
│   ├── (auth)/         # Auth pages group
│   ├── dashboard/      # Dashboard pages
│   └── api/            # API routes
├── components/           # React components
│   ├── ui/             # Base UI components
│   ├── auth/           # Auth-specific components
│   ├── layouts/        # Layout components
│   └── features/       # Feature-specific components
├── lib/                  # Utilities and configuration
│   ├── supabase/       # Supabase client setup
│   ├── stripe/         # Stripe configuration
│   ├── email/          # Email utilities
│   └── auth/           # Auth utilities
└── hooks/                # Custom React hooks
```

### Backend (Supabase)
```
supabase/
├── migrations/         # Database migrations
├── functions/          # Edge functions
├── policies/           # RLS policies
└── seed/               # Seed data
```

## Development Workflow

1. **Start Supabase locally**
   ```bash
   cd supabase
   supabase start
   ```

2. **Run database migrations**
   ```bash
   supabase db reset
   ```

3. **Start frontend development server**
   ```bash
   cd frontend
   pnpm dev
   ```

4. **Generate types after schema changes**
   ```bash
   supabase gen types typescript --local > ../shared/types/database.ts
   ```

## Key Features Implementation

### Authentication
- Uses Supabase Auth with email/password and OAuth
- Protected routes via middleware
- User profiles stored in `profiles` table

### Payments
- Stripe Checkout for subscriptions
- Webhooks handle subscription events
- Customer portal for self-service

### Email
- Resend for transactional emails
- React Email for templates
- Automated welcome/reset emails

## Testing

Run tests with:
```bash
pnpm test         # Single run
pnpm test:watch   # Watch mode
pnpm test:coverage # With coverage
```

## Debugging

### Common Issues
1. **Supabase connection issues** - Check environment variables
2. **Stripe webhook failures** - Verify webhook secret
3. **Email sending fails** - Check Resend API key

### Useful Commands
```bash
# Check Supabase status
supabase status

# View Supabase logs
supabase functions logs

# Reset database
supabase db reset

# Generate new migration
supabase migration new migration_name
```
GUIDE

    # Deployment guide
    cat > docs/deployment.md << 'DEPLOY'
# Deployment Guide

## Supabase Setup

1. **Create Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Create new project
   - Note your project URL and anon key

2. **Deploy Database Schema**
   ```bash
   supabase link --project-ref your-project-ref
   supabase db push
   ```

3. **Deploy Edge Functions**
   ```bash
   supabase functions deploy stripe-webhook
   supabase functions deploy send-email
   ```

## Stripe Setup

1. **Create Stripe Account**
   - Set up products and prices
   - Configure webhooks pointing to your edge function
   - Copy API keys

2. **Required Stripe Events**
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`

## Vercel Deployment

1. **Connect Repository**
   - Import your GitHub repository
   - Configure environment variables

2. **Environment Variables**
   ```env
   NEXT_PUBLIC_SUPABASE_URL=
   NEXT_PUBLIC_SUPABASE_ANON_KEY=
   SUPABASE_SERVICE_ROLE_KEY=
   NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
   STRIPE_SECRET_KEY=
   STRIPE_WEBHOOK_SECRET=
   RESEND_API_KEY=
   NEXT_PUBLIC_APP_URL=
   ```

3. **Deploy**
   - Push to main branch
   - Vercel automatically deploys

## Alternative Deployments

### Docker
```bash
# Build image
docker build -t saas-app .

# Run container
docker run -p 3000:3000 saas-app
```

### Railway
1. Connect GitHub repository
2. Set environment variables
3. Deploy automatically

### Netlify
1. Connect repository
2. Set build command: `pnpm build`
3. Set publish directory: `frontend/.next`

## Post-Deployment Checklist

- [ ] Database schema deployed
- [ ] Edge functions working
- [ ] Stripe webhooks configured
- [ ] Email sending functional
- [ ] Environment variables set
- [ ] Domain configured
- [ ] SSL certificate active
- [ ] Monitoring setup (optional)

## Monitoring

### Recommended Tools
- **Sentry** - Error tracking
- **Vercel Analytics** - Performance monitoring
- **Supabase Dashboard** - Database monitoring
- **Stripe Dashboard** - Payment monitoring

### Health Checks
Create monitoring for:
- Application uptime
- Database connectivity
- Stripe webhook delivery
- Email delivery rates
DEPLOY
    log_success "Documentation created"
}

# Show next steps
show_next_steps() {
    echo ""
    echo "🎉 ${GREEN}Enhanced Lean SaaS Template Setup Complete!${NC}"
    echo ""
    echo "📁 ${BLUE}Project Structure:${NC}"
    echo "   ├── ${CYAN}frontend/${NC}        Complete Next.js 14 app with TypeScript"
    echo "   ├── ${CYAN}supabase/${NC}        Database, auth, and edge functions"
    echo "   ├── ${CYAN}shared/${NC}          Shared types and utilities"
    echo "   ├── ${CYAN}docs/${NC}            Comprehensive documentation"
    echo "   └── ${CYAN}setup-modules/${NC}   Individual setup scripts"
    echo ""
    echo "🚀 ${BLUE}Next Steps:${NC}"
    echo "   ${YELLOW}1.${NC} Configure environment variables:"
    echo "      ${CYAN}cp frontend/.env.local.example frontend/.env.local${NC}"
    echo "      ${CYAN}# Edit with your API keys${NC}"
    echo ""
    echo "   ${YELLOW}2.${NC} Start Supabase locally:"
    echo "      ${CYAN}cd supabase && supabase start${NC}"
    echo ""
    echo "   ${YELLOW}3.${NC} Install dependencies and start development:"
    echo "      ${CYAN}cd frontend && pnpm install && pnpm dev${NC}"
    echo ""
    echo "   ${YELLOW}4.${NC} Open VSCode workspace:"
    echo "      ${CYAN}code .vscode/saas-app.code-workspace${NC}"
    echo ""
    echo "📚 ${BLUE}Documentation:${NC}"
    echo "   • ${CYAN}README.md${NC} - Complete project overview"
    echo "   • ${CYAN}docs/development.md${NC} - Development workflow"
    echo "   • ${CYAN}docs/deployment.md${NC} - Production deployment"
    echo ""
    echo "✨ ${BLUE}What's Included:${NC}"
    echo "   ✅ Authentication system (email/OAuth)"
    echo "   ✅ Payment integration (Stripe subscriptions)"
    echo "   ✅ Email system (Resend + React Email)"
    echo "   ✅ Dashboard with user management"
    echo "   ✅ Database schema with RLS policies"
    echo "   ✅ UI components library"
    echo "   ✅ Testing setup (Jest + Testing Library)"
    echo "   ✅ CI/CD pipelines (GitHub Actions)"
    echo "   ✅ Docker support"
    echo "   ✅ TypeScript throughout"
    echo ""
    echo "🎯 ${GREEN}Ready to build your SaaS!${NC}"
    echo ""
}

# Hàm thực thi chính
main() {
    log_step "Starting Enhanced Lean SaaS Setup for: $PROJECT_NAME"
    
    check_dependencies
    
    log_step "Setting up modules directory..."
    mkdir -p setup-modules
    cd setup-modules

    # Tạo tất cả các file script con bằng hàm điều phối
    write_module "01" "project-structure"
    write_module "02" "frontend-setup"
    write_module "03" "supabase-setup"
    write_module "04" "auth-system"
    write_module "05" "ui-components"
    write_module "06" "payment-system"
    write_module "07" "dashboard-setup"
    write_module "08" "email-system"
    write_module "09" "dev-tools"
    
    cd ..
    log_success "All module scripts have been created."

    # Thực thi các module theo tuần tự
    log_step "Executing setup modules..."
    
    ./setup-modules/01-project-structure.sh "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    
    ../setup-modules/02-frontend-setup.sh
    ../setup-modules/03-supabase-setup.sh
    ../setup-modules/04-auth-system.sh
    ../setup-modules/05-ui-components.sh
    ../setup-modules/06-payment-system.sh
    ../setup-modules/07-dashboard-setup.sh
    ../setup-modules/08-email-system.sh
    ../setup-modules/09-dev-tools.sh
    
    # Tạo các file cuối cùng và hiển thị hướng dẫn
    create_project_readme
    create_environment_files
    create_final_documentation
    
    log_success "Enhanced Lean SaaS template setup completed!"
    show_next_steps
}

# Bắt đầu thực thi chương trình
main
