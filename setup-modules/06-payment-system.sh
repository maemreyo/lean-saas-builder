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
