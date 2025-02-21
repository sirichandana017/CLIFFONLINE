import React, { useState } from 'react';
import { Mail, Lock, Loader2, Building2, Phone, MapPin, Building, Store } from 'lucide-react';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';

type AuthMode = 'signin' | 'login';
type UserType = 'wholesaler' | 'retailer' | 'customer';

interface RegistrationFields {
  firstName?: string;
  lastName?: string;
  address?: string;
  phone?: string;
  companyName?: string;
  industryType?: string;
  businessName?: string;
  businessType?: string;
  businessAddress?: string;
  userType?: UserType;
}

const INDUSTRY_TYPES = [
  'Clothing',
  'Footwear',
  'Electronics',
  'Furniture',
  'Food & Beverages',
  'Stationary',
  'Other'
];

export function AuthForm() {
  const navigate = useNavigate();
  const [mode, setMode] = useState<AuthMode>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [fields, setFields] = useState<RegistrationFields>({});

  // Get user type from URL
  const userType = window.location.pathname.split('/')[1] as UserType;

  const validateFields = () => {
    if (!email.trim()) throw new Error('Email is required');
    if (!password.trim()) throw new Error('Password is required');
    
    // Validate email format
    const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
    if (!emailRegex.test(email.trim())) {
      throw new Error('Please enter a valid email address');
    }

    if (mode === 'signin') {
      if (!fields.firstName?.trim()) throw new Error('First name is required');
      if (!fields.lastName?.trim()) throw new Error('Last name is required');
      if (!fields.phone?.trim()) throw new Error('Phone number is required');
      if (!fields.address?.trim()) throw new Error('Address is required');

      if (userType === 'wholesaler') {
        if (!fields.companyName?.trim()) throw new Error('Company name is required');
        if (!fields.industryType?.trim()) throw new Error('Industry type is required');
      }

      if (userType === 'retailer') {
        if (!fields.businessName?.trim()) throw new Error('Business name is required');
        if (!fields.businessType?.trim()) throw new Error('Business type is required');
        if (!fields.businessAddress?.trim()) throw new Error('Business address is required');
        if (!fields.industryType?.trim()) throw new Error('Industry type is required');
      }

      // Validate password requirements
      if (password.length < 6) {
        throw new Error('Password must be at least 6 characters long');
      }

      if (password !== confirmPassword) {
        throw new Error('Passwords do not match');
      }
    }
  };

  const handleAuth = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);

      // Validate fields
      validateFields();

      if (mode === 'signin') {
        // Prepare user metadata
        const metadata = {
          userType,
          firstName: fields.firstName?.trim(),
          lastName: fields.lastName?.trim(),
          phone: fields.phone?.trim(),
          address: fields.address?.trim(),
          ...(userType === 'wholesaler' && {
            companyName: fields.companyName?.trim(),
            industryType: fields.industryType?.trim(),
          }),
          ...(userType === 'retailer' && {
            businessName: fields.businessName?.trim(),
            businessType: fields.businessType?.trim(),
            businessAddress: fields.businessAddress?.trim(),
            industryType: fields.industryType?.trim(),
          }),
        };

        // Create user with email verification
        const { error: signUpError } = await supabase.auth.signUp({
          email: email.trim().toLowerCase(),
          password,
          options: {
            data: metadata,
          },
        });

        if (signUpError) {
          if (signUpError.message.includes('User already registered')) {
            throw new Error('This email is already registered. Please log in instead.');
          }
          throw new Error(signUpError.message || 'Failed to create account. Please try again.');
        }

        toast.success('Account created successfully! You can now log in.');
        setMode('login');
      } else {
        // Login
        const { data, error } = await supabase.auth.signInWithPassword({
          email: email.trim().toLowerCase(),
          password,
        });

        if (error) {
          if (error.message.includes('Invalid login credentials')) {
            throw new Error('Invalid email or password. Please try again.');
          }
          throw new Error(error.message || 'Failed to log in. Please try again.');
        }

        if (data.user) {
          // Get user profile to verify user type
          const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('user_type')
            .eq('id', data.user.id)
            .single();

          if (profileError) {
            throw new Error('Failed to verify user type. Please try again.');
          }

          if (profile.user_type !== userType) {
            throw new Error(`This account is registered as a ${profile.user_type}. Please use the correct login page.`);
          }

          toast.success('Successfully logged in!');
          navigate(`/${userType}/dashboard`);
        }
      }
    } catch (error: any) {
      toast.error(error.message);
      console.error('Auth error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleAuth} className="space-y-4 w-full max-w-sm">
      {mode === 'signin' && (
        <>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                First Name
              </label>
              <input
                type="text"
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 p-2"
                value={fields.firstName || ''}
                onChange={(e) => setFields({ ...fields, firstName: e.target.value })}
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Last Name
              </label>
              <input
                type="text"
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 p-2"
                value={fields.lastName || ''}
                onChange={(e) => setFields({ ...fields, lastName: e.target.value })}
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Phone Number
            </label>
            <div className="mt-1 relative rounded-md shadow-sm">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Phone className="h-5 w-5 text-gray-400" />
              </div>
              <input
                type="tel"
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                value={fields.phone || ''}
                onChange={(e) => setFields({ ...fields, phone: e.target.value })}
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Address
            </label>
            <div className="mt-1 relative rounded-md shadow-sm">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <MapPin className="h-5 w-5 text-gray-400" />
              </div>
              <input
                type="text"
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                value={fields.address || ''}
                onChange={(e) => setFields({ ...fields, address: e.target.value })}
                required
              />
            </div>
          </div>

          {userType === 'wholesaler' && (
            <>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Company Name
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Building2 className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    type="text"
                    className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    value={fields.companyName || ''}
                    onChange={(e) => setFields({ ...fields, companyName: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Industry Type
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Store className="h-5 w-5 text-gray-400" />
                  </div>
                  <select
                    className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    value={fields.industryType || ''}
                    onChange={(e) => setFields({ ...fields, industryType: e.target.value })}
                    required
                  >
                    <option value="">Select Industry Type</option>
                    {INDUSTRY_TYPES.map(type => (
                      <option key={type} value={type.toLowerCase()}>
                        {type}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </>
          )}

          {userType === 'retailer' && (
            <>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Business Name
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Building className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    type="text"
                    className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    value={fields.businessName || ''}
                    onChange={(e) => setFields({ ...fields, businessName: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Business Type
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Store className="h-5 w-5 text-gray-400" />
                  </div>
                  <select
                    className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    value={fields.businessType || ''}
                    onChange={(e) => setFields({ ...fields, businessType: e.target.value })}
                    required
                  >
                    <option value="">Select Business Type</option>
                    <option value="retail_store">Retail Store</option>
                    <option value="online_store">Online Store</option>
                    <option value="hybrid">Hybrid (Online & Physical)</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Industry Type
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Store className="h-5 w-5 text-gray-400" />
                  </div>
                  <select
                    className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    value={fields.industryType || ''}
                    onChange={(e) => setFields({ ...fields, industryType: e.target.value })}
                    required
                  >
                    <option value="">Select Industry Type</option>
                    {INDUSTRY_TYPES.map(type => (
                      <option key={type} value={type.toLowerCase()}>
                        {type}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Business Address
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <MapPin className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    type="text"
                    className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    value={fields.businessAddress || ''}
                    onChange={(e) => setFields({ ...fields, businessAddress: e.target.value })}
                    required
                  />
                </div>
              </div>
            </>
          )}
        </>
      )}

      <div>
        <label className="block text-sm font-medium text-gray-700">
          Email address
        </label>
        <div className="mt-1 relative rounded-md shadow-sm">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Mail className="h-5 w-5 text-gray-400" />
          </div>
          <input
            type="email"
            className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            required
          />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">
          Password
        </label>
        <div className="mt-1 relative rounded-md shadow-sm">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Lock className="h-5 w-5 text-gray-400" />
          </div>
          <input
            type="password"
            className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            required
            minLength={6}
          />
        </div>
      </div>

      {mode === 'signin' && (
        <div>
          <label className="block text-sm font-medium text-gray-700">
            Confirm Password
          </label>
          <div className="mt-1 relative rounded-md shadow-sm">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Lock className="h-5 w-5 text-gray-400" />
            </div>
            <input
              type="password"
              className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="••••••••"
              required
              minLength={6}
            />
          </div>
        </div>
      )}

      <button
        type="submit"
        disabled={loading || (mode === 'signin' && password !== confirmPassword)}
        className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
      >
        {loading ? (
          <Loader2 className="w-5 h-5 animate-spin" />
        ) : mode === 'signin' ? (
          'Sign Up'
        ) : (
          'Log In'
        )}
      </button>

      <p className="text-center text-sm text-gray-600">
        {mode === 'signin' ? 'Already have an account?' : "Don't have an account?"}{' '}
        <button
          type="button"
          onClick={() => {
            setMode(mode === 'signin' ? 'login' : 'signin');
            setConfirmPassword('');
          }}
          className="font-medium text-blue-600 hover:text-blue-500"
        >
          {mode === 'signin' ? 'Log in' : 'Sign up'}
        </button>
      </p>
    </form>
  );
}